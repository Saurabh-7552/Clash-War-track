# PowerShell Deployment Script for Clash War Tracker on AWS EC2
# Customized for Windows environment

param(
    [switch]$SkipBuild,
    [switch]$SkipInfrastructure,
    [switch]$SkipSSL
)

# Configuration
$ELASTIC_IP = "13.48.112.177"
$AWS_REGION = "eu-north-1"
$KEY_PAIR_NAME = "myclashkey"
$DOMAIN_NAME = "clashtrack.ai"

Write-Host "🚀 Clash War Tracker - JAR Deployment to AWS EC2" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

function Write-Status($message) {
    Write-Host "[INFO] $message" -ForegroundColor Blue
}

function Write-Success($message) {
    Write-Host "[SUCCESS] $message" -ForegroundColor Green
}

function Write-Warning($message) {
    Write-Host "[WARNING] $message" -ForegroundColor Yellow
}

function Write-Error($message) {
    Write-Host "[ERROR] $message" -ForegroundColor Red
}

# Check prerequisites
function Test-Prerequisites {
    Write-Status "Checking prerequisites..."
    
    # Check AWS CLI
    try {
        $awsVersion = aws --version 2>$null
        Write-Success "AWS CLI found: $awsVersion"
    }
    catch {
        Write-Error "AWS CLI is not installed or not in PATH"
        return $false
    }
    
    # Check Terraform
    try {
        $terraformVersion = terraform --version 2>$null
        Write-Success "Terraform found: $terraformVersion"
    }
    catch {
        Write-Error "Terraform is not installed or not in PATH"
        Write-Warning "Please add Terraform to your PATH or run from Terraform directory"
        return $false
    }
    
    # Check AWS credentials
    try {
        aws sts get-caller-identity | Out-Null
        Write-Success "AWS credentials configured"
    }
    catch {
        Write-Error "AWS credentials not configured. Run 'aws configure' first"
        return $false
    }
    
    # Check key pair file
    $keyPath = "F:\GITHUB\track_clash\$KEY_PAIR_NAME.pem"
    if (-not (Test-Path $keyPath)) {
        Write-Error "Key pair file not found: $keyPath"
        Write-Warning "Please place your key pair file in F:\GITHUB\track_clash\"
        return $false
    }
    
    Write-Success "Prerequisites check passed"
    return $true
}

# Build application
function Build-Application {
    if ($SkipBuild) {
        Write-Warning "Skipping build (SkipBuild flag set)"
        return
    }
    
    Write-Status "Building Spring Boot application..."
    
    # Build JAR file
    & .\mvnw.cmd clean package -DskipTests
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Maven build failed"
        exit 1
    }
    
    $jarFile = Get-ChildItem -Path "target" -Filter "*.jar" | Select-Object -First 1
    if (-not $jarFile) {
        Write-Error "JAR file not found in target/ directory"
        exit 1
    }
    
    Write-Success "JAR built: $($jarFile.Name)"
    
    # Build frontend
    Write-Status "Building React frontend..."
    Set-Location "clash-war-tracker-frontend"
    npm install
    npm run build
    Set-Location ".."
    
    if (-not (Test-Path "clash-war-tracker-frontend\dist")) {
        Write-Error "Frontend build not found"
        exit 1
    }
    
    Write-Success "Application built successfully"
}

# Deploy infrastructure with Terraform
function Deploy-Infrastructure {
    if ($SkipInfrastructure) {
        Write-Warning "Skipping infrastructure deployment (SkipInfrastructure flag set)"
        return
    }
    
    Write-Status "Deploying AWS infrastructure..."
    
    Set-Location "aws-deployment\terraform"
    
    # Initialize Terraform
    terraform init
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Terraform init failed"
        exit 1
    }
    
    # Plan deployment
    terraform plan -var-file="terraform.tfvars"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Terraform plan failed"
        exit 1
    }
    
    Write-Host ""
    $proceed = Read-Host "Do you want to proceed with infrastructure deployment? (y/N)"
    
    if ($proceed -eq 'y' -or $proceed -eq 'Y') {
        terraform apply -var-file="terraform.tfvars" -auto-approve
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Terraform apply failed"
            exit 1
        }
        Write-Success "Infrastructure deployed successfully"
    }
    else {
        Write-Warning "Infrastructure deployment cancelled"
        exit 0
    }
    
    Set-Location "..\..\"
}

# Wait for EC2 instance to be ready
function Wait-ForInstance {
    Write-Status "Waiting for EC2 instance to be ready..."
    
    $maxAttempts = 30
    $attempt = 1
    
    while ($attempt -le $maxAttempts) {
        try {
            # Test SSH connection
            $testResult = ssh -i "F:\GITHUB\track_clash\$KEY_PAIR_NAME.pem" -o ConnectTimeout=10 -o StrictHostKeyChecking=no ec2-user@$ELASTIC_IP "echo 'Instance ready'" 2>$null
            if ($testResult -eq "Instance ready") {
                Write-Success "EC2 instance is ready"
                return
            }
        }
        catch {
            # Connection failed, continue waiting
        }
        
        Write-Status "Attempt $attempt/$maxAttempts - waiting for instance..."
        Start-Sleep -Seconds 30
        $attempt++
    }
    
    Write-Error "EC2 instance not ready after $maxAttempts attempts"
    exit 1
}

# Upload and deploy application
function Deploy-Application {
    Write-Status "Uploading and deploying application..."
    
    # Find JAR file
    $jarFile = Get-ChildItem -Path "target" -Filter "*.jar" | Select-Object -First 1
    if (-not $jarFile) {
        Write-Error "JAR file not found in target/ directory"
        exit 1
    }
    
    Write-Status "Uploading JAR file: $($jarFile.Name)"
    scp -i "F:\GITHUB\track_clash\$KEY_PAIR_NAME.pem" "$($jarFile.FullName)" "ec2-user@${ELASTIC_IP}:/tmp/clash-war-tracker-backend.jar"
    
    Write-Status "Uploading frontend build"
    scp -i "F:\GITHUB\track_clash\$KEY_PAIR_NAME.pem" -r "clash-war-tracker-frontend\dist" "ec2-user@${ELASTIC_IP}:/tmp/frontend-dist"
    
    Write-Status "Deploying application on EC2..."
    
    # Create deployment commands
    $deployCommands = @"
# Wait for user-data script to complete
while [ ! -f /var/log/cloud-init-output.log ] || ! grep -q "Cloud-init.*finished" /var/log/cloud-init-output.log; do
    echo "Waiting for EC2 initialization to complete..."
    sleep 30
done

# Run deployment script
sudo /opt/clash-tracker/deploy.sh

# Check service status
sudo systemctl status clash-tracker-backend --no-pager
sudo systemctl status clash-tracker-frontend --no-pager
sudo systemctl status nginx --no-pager
"@
    
    ssh -i "F:\GITHUB\track_clash\$KEY_PAIR_NAME.pem" ec2-user@$ELASTIC_IP $deployCommands
    
    Write-Success "Application deployed successfully"
}

# Test deployment
function Test-Deployment {
    Write-Status "Testing deployment..."
    
    # Wait for services to start
    Start-Sleep -Seconds 30
    
    # Test backend health
    Write-Status "Testing backend health endpoint..."
    try {
        $response = Invoke-WebRequest -Uri "http://${ELASTIC_IP}:8080/api/health" -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Success "✅ Backend is responding: $($response.Content)"
        }
    }
    catch {
        Write-Warning "⚠️ Backend health check failed: $($_.Exception.Message)"
    }
    
    # Test API with new key
    Write-Status "Testing Clash of Clans API..."
    try {
        $response = Invoke-WebRequest -Uri "http://${ELASTIC_IP}:8080/api/fetch-currentwar?clanTag=%232GC8P2L88" -TimeoutSec 10 -UseBasicParsing
        $content = $response.Content
        if ($content -ne "[]" -and $content -ne "ERROR") {
            Write-Success "✅ Clash of Clans API is working"
        }
        else {
            Write-Warning "⚠️ Clash of Clans API test failed: $content"
        }
    }
    catch {
        Write-Warning "⚠️ Clash of Clans API test failed: $($_.Exception.Message)"
    }
    
    # Test frontend
    Write-Status "Testing frontend..."
    try {
        $response = Invoke-WebRequest -Uri "http://${ELASTIC_IP}" -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Success "✅ Frontend is responding"
        }
    }
    catch {
        Write-Warning "⚠️ Frontend health check failed: $($_.Exception.Message)"
    }
    
    Write-Success "Deployment testing completed"
}

# Setup SSL certificate
function Setup-SSL {
    if ($SkipSSL) {
        Write-Warning "Skipping SSL setup (SkipSSL flag set)"
        return
    }
    
    Write-Status "Setting up SSL certificate for $DOMAIN_NAME..."
    
    Write-Host ""
    Write-Warning "⚠️ IMPORTANT: Before setting up SSL, make sure:"
    Write-Warning "   1. Domain $DOMAIN_NAME points to $ELASTIC_IP"
    Write-Warning "   2. DNS propagation is complete (check with: nslookup $DOMAIN_NAME)"
    Write-Host ""
    
    $proceed = Read-Host "Is your domain $DOMAIN_NAME pointing to $ELASTIC_IP? (y/N)"
    
    if ($proceed -eq 'y' -or $proceed -eq 'Y') {
        ssh -i "F:\GITHUB\track_clash\$KEY_PAIR_NAME.pem" ec2-user@$ELASTIC_IP 'sudo /opt/clash-tracker/setup-ssl.sh'
        Write-Success "SSL certificate setup initiated"
    }
    else {
        Write-Warning "SSL setup skipped. Run this later:"
        Write-Host "ssh -i `"F:\GITHUB\track_clash\$KEY_PAIR_NAME.pem`" ec2-user@$ELASTIC_IP 'sudo /opt/clash-tracker/setup-ssl.sh'" -ForegroundColor Cyan
    }
}

# Main deployment process
function Main {
    Write-Host "Starting JAR deployment process..." -ForegroundColor Green
    Write-Host "Elastic IP: $ELASTIC_IP" -ForegroundColor Cyan
    Write-Host "Domain: $DOMAIN_NAME" -ForegroundColor Cyan
    Write-Host "Key Pair: $KEY_PAIR_NAME" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Test-Prerequisites)) {
        exit 1
    }
    
    Build-Application
    Deploy-Infrastructure
    Wait-ForInstance
    Deploy-Application
    Test-Deployment
    Setup-SSL
    
    Write-Host ""
    Write-Success "🎉 Deployment completed successfully!"
    Write-Host ""
    Write-Host "📋 Access Information:" -ForegroundColor Yellow
    Write-Host "   Domain:    https://$DOMAIN_NAME (after SSL setup)" -ForegroundColor Cyan
    Write-Host "   IP Access: http://$ELASTIC_IP" -ForegroundColor Cyan
    Write-Host "   Backend:   http://${ELASTIC_IP}:8080" -ForegroundColor Cyan
    Write-Host "   SSH:       ssh -i `"F:\GITHUB\track_clash\$KEY_PAIR_NAME.pem`" ec2-user@$ELASTIC_IP" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📝 Next Steps:" -ForegroundColor Yellow
    Write-Host "   1. Point domain $DOMAIN_NAME to $ELASTIC_IP" -ForegroundColor White
    Write-Host "   2. Wait for DNS propagation" -ForegroundColor White
    Write-Host "   3. Run SSL setup" -ForegroundColor White
    Write-Host "   4. Test the application at https://$DOMAIN_NAME" -ForegroundColor White
}

# Run main function
Main

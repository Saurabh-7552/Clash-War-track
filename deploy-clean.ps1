# Clean Deployment Script for Clash War Tracker
param(
    [string]$ElasticIP = "13.48.112.177",
    [string]$KeyPath = "F:\GITHUB\track_clash\myclashkey.pem"
)

Write-Host "Deploying Clash War Tracker to EC2..." -ForegroundColor Green
Write-Host "Target: $ElasticIP" -ForegroundColor Cyan

# Test SSH connection
Write-Host "Testing SSH connection..." -ForegroundColor Blue
$testResult = ssh -i "$KeyPath" -o ConnectTimeout=10 -o StrictHostKeyChecking=no ec2-user@$ElasticIP "echo 'Connected'" 2>$null

if ($testResult -ne "Connected") {
    Write-Host "SSH connection failed" -ForegroundColor Red
    exit 1
}

Write-Host "SSH connection successful" -ForegroundColor Green

# Create source archive
Write-Host "Creating source archive..." -ForegroundColor Blue
$zipPath = "clash-tracker-source.zip"

if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

# Create zip using PowerShell
Compress-Archive -Path "src", "pom.xml", "clash-war-tracker-frontend" -DestinationPath $zipPath -Force

Write-Host "Uploading source to EC2..." -ForegroundColor Blue
scp -i "$KeyPath" $zipPath ec2-user@${ElasticIP}:/tmp/

Write-Host "Building on EC2..." -ForegroundColor Blue

# Simple deployment command
$deployCmd = @"
cd /tmp && 
unzip -o clash-tracker-source.zip && 
sudo yum install -y maven && 
mvn clean package -DskipTests && 
cd clash-war-tracker-frontend && 
npm install && 
npm run build && 
cd .. && 
sudo mkdir -p /opt/clash-tracker/app /opt/clash-tracker/frontend && 
sudo cp target/*.jar /opt/clash-tracker/app/clash-war-tracker-backend.jar && 
sudo cp -r clash-war-tracker-frontend/dist /opt/clash-tracker/frontend/ && 
sudo chown -R clash-tracker:clash-tracker /opt/clash-tracker && 
echo "Build completed"
"@

ssh -i "$KeyPath" ec2-user@$ElasticIP $deployCmd

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build completed successfully!" -ForegroundColor Green
    Remove-Item $zipPath -Force
    
    Write-Host ""
    Write-Host "Your application is being built on EC2" -ForegroundColor Yellow
    Write-Host "Next: Run configure-ec2-app.ps1 to start services" -ForegroundColor Cyan
} else {
    Write-Host "Build failed - check output above" -ForegroundColor Red
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
}

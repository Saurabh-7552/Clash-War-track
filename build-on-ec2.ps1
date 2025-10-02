# Build Application on EC2 Instance
# This script uploads source code to EC2 and builds it there

param(
    [string]$ElasticIP = "13.48.112.177",
    [string]$KeyPath = "F:\GITHUB\track_clash\myclashkey.pem"
)

Write-Host "🚀 Building Clash War Tracker on EC2..." -ForegroundColor Green

# Wait for EC2 to be ready
Write-Host "⏳ Waiting for EC2 instance to be ready..." -ForegroundColor Yellow
$maxAttempts = 20
$attempt = 1

while ($attempt -le $maxAttempts) {
    try {
        $testResult = ssh -i "$KeyPath" -o ConnectTimeout=10 -o StrictHostKeyChecking=no ec2-user@$ElasticIP "echo 'ready'" 2>$null
        if ($testResult -eq "ready") {
            Write-Host "✅ EC2 instance is ready!" -ForegroundColor Green
            break
        }
    }
    catch {
        # Continue waiting
    }
    
    Write-Host "   Attempt $attempt/$maxAttempts - waiting..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    $attempt++
}

if ($attempt -gt $maxAttempts) {
    Write-Host "❌ EC2 instance not ready. Please check AWS console." -ForegroundColor Red
    exit 1
}

# Create source archive (excluding unnecessary files)
Write-Host "📦 Creating source archive..." -ForegroundColor Blue
$excludePatterns = @(
    "target",
    "node_modules", 
    ".git",
    "*.log",
    ".terraform",
    "clash-war-tracker-frontend/dist"
)

# Create temporary directory and copy source
$tempDir = "temp-source"
if (Test-Path $tempDir) {
    Remove-Item -Recurse -Force $tempDir
}
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Copy source files
Copy-Item -Path "src" -Destination "$tempDir/src" -Recurse
Copy-Item -Path "pom.xml" -Destination "$tempDir/"
Copy-Item -Path "clash-war-tracker-frontend" -Destination "$tempDir/" -Recurse -Exclude "node_modules", "dist"

# Create tar archive
tar -czf clash-tracker-source.tar.gz -C $tempDir .
Remove-Item -Recurse -Force $tempDir

Write-Host "📤 Uploading source to EC2..." -ForegroundColor Blue
scp -i "$KeyPath" clash-tracker-source.tar.gz ec2-user@${ElasticIP}:/tmp/

Write-Host "🔨 Building application on EC2..." -ForegroundColor Blue
$buildCommands = 'while [ ! -f /var/log/clash-tracker-setup.log ]; do echo "Waiting for EC2 setup..."; sleep 10; done && cd /tmp && tar -xzf clash-tracker-source.tar.gz && sudo yum install -y maven && mvn clean package -DskipTests && cd clash-war-tracker-frontend && npm install && npm run build && cd .. && sudo mkdir -p /opt/clash-tracker/{app,frontend} && sudo cp target/*.jar /opt/clash-tracker/app/clash-war-tracker-backend.jar && sudo cp -r clash-war-tracker-frontend/dist /opt/clash-tracker/frontend/ && sudo chown -R clash-tracker:clash-tracker /opt/clash-tracker && echo "Build completed successfully!"'

ssh -i "$KeyPath" ec2-user@$ElasticIP $buildCommands

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Application built successfully on EC2!" -ForegroundColor Green
    
    # Clean up local files
    Remove-Item clash-tracker-source.tar.gz
    
    Write-Host ""
    Write-Host "📋 Next Steps:" -ForegroundColor Yellow
    Write-Host "   1. Configure application services" -ForegroundColor White
    Write-Host "   2. Start the application" -ForegroundColor White
    Write-Host "   3. Test endpoints" -ForegroundColor White
    Write-Host ""
    Write-Host "🔗 Run configuration script:" -ForegroundColor Cyan
    Write-Host "   .\configure-ec2-app.ps1" -ForegroundColor White
}
else {
    Write-Host "❌ Build failed. Check the output above for errors." -ForegroundColor Red
    exit 1
}

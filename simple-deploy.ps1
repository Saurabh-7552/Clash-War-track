# Simple Deployment Script for Clash War Tracker
param(
    [string]$ElasticIP = "13.48.112.177",
    [string]$KeyPath = "F:\GITHUB\track_clash\myclashkey.pem"
)

Write-Host "🚀 Deploying Clash War Tracker to EC2..." -ForegroundColor Green
Write-Host "Target: $ElasticIP" -ForegroundColor Cyan

# Test SSH connection
Write-Host "🔍 Testing SSH connection..." -ForegroundColor Blue
try {
    $testResult = ssh -i "$KeyPath" -o ConnectTimeout=10 -o StrictHostKeyChecking=no ec2-user@$ElasticIP "echo 'Connected'" 2>$null
    if ($testResult -eq "Connected") {
        Write-Host "✅ SSH connection successful" -ForegroundColor Green
    }
    else {
        Write-Host "❌ SSH connection failed" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "❌ SSH connection error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Create and upload source archive
Write-Host "📦 Creating source archive..." -ForegroundColor Blue

# Create a simple tar command that works on Windows
$sourceFiles = @(
    "src",
    "pom.xml", 
    "clash-war-tracker-frontend"
)

# Use PowerShell to create a zip instead of tar for Windows compatibility
$zipPath = "clash-tracker-source.zip"
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

# Create zip archive
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)

# Add source files
Get-ChildItem -Path "src" -Recurse | ForEach-Object {
    $relativePath = $_.FullName.Substring((Get-Location).Path.Length + 1)
    if ($_.PSIsContainer -eq $false) {
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $relativePath) | Out-Null
    }
}

# Add pom.xml
[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, "pom.xml", "pom.xml") | Out-Null

# Add frontend files (excluding node_modules and dist)
Get-ChildItem -Path "clash-war-tracker-frontend" -Recurse | Where-Object { 
    $_.FullName -notmatch "node_modules" -and $_.FullName -notmatch "\\dist\\" 
} | ForEach-Object {
    $relativePath = $_.FullName.Substring((Get-Location).Path.Length + 1)
    if ($_.PSIsContainer -eq $false) {
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $relativePath) | Out-Null
    }
}

$zip.Dispose()

Write-Host "📤 Uploading source to EC2..." -ForegroundColor Blue
scp -i "$KeyPath" $zipPath ec2-user@${ElasticIP}:/tmp/

Write-Host "🔨 Building and configuring on EC2..." -ForegroundColor Blue

# Execute deployment on EC2
ssh -i "$KeyPath" ec2-user@$ElasticIP @"
echo "Starting deployment process..."

# Wait for EC2 setup to complete
echo "Waiting for EC2 setup to complete..."
while [ ! -f /var/log/clash-tracker-setup.log ]; do
    echo "Still waiting for setup..."
    sleep 10
done
echo "EC2 setup completed"

# Extract source
cd /tmp
echo "Extracting source..."
unzip -q clash-tracker-source.zip
ls -la

# Install Maven
echo "Installing Maven..."
sudo yum install -y maven

# Build Spring Boot application
echo "Building Spring Boot JAR..."
mvn clean package -DskipTests
if [ \$? -ne 0 ]; then
    echo "Maven build failed"
    exit 1
fi

# Build frontend
echo "Building React frontend..."
cd clash-war-tracker-frontend
npm install
npm run build
if [ \$? -ne 0 ]; then
    echo "Frontend build failed"
    exit 1
fi
cd ..

# Setup application directories
echo "Setting up application..."
sudo mkdir -p /opt/clash-tracker/{app,frontend,config,logs}
sudo cp target/*.jar /opt/clash-tracker/app/clash-war-tracker-backend.jar
sudo cp -r clash-war-tracker-frontend/dist /opt/clash-tracker/frontend/
sudo chown -R clash-tracker:clash-tracker /opt/clash-tracker

# Create application configuration
echo "Creating configuration..."
sudo tee /opt/clash-tracker/config/application-prod.properties > /dev/null << 'EOF'
server.port=8080
spring.datasource.url=jdbc:postgresql://localhost:5432/clash_tracker
spring.datasource.username=clash_tracker_user
spring.datasource.password=verma2017
spring.datasource.driver-class-name=org.postgresql.Driver
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=false
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect
spring.datasource.hikari.maximum-pool-size=20
spring.datasource.hikari.minimum-idle=5
clash.api.key=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiIsImtpZCI6IjI4YTMxOGY3LTAwMDAtYTFlYi03ZmExLTJjNzQzM2M2Y2NhNSJ9.eyJpc3MiOiJzdXBlcmNlbGwiLCJhdWQiOiJzdXBlcmNlbGw6Z2FtZWFwaSIsImp0aSI6IjczOTczYjAwLWY0MzUtNDA3OC1hYmUwLTZkMmNkYWE1MTFiNyIsImlhdCI6MTc1OTM4MzM2Niwic3ViIjoiZGV2ZWxvcGVyLzA3MzMzZTY3LTA4NTEtNTk5Ny1iZWEyLTA5ZDY2MjBlMDhiOCIsInNjb3BlcyI6WyJjbGFzaCJdLCJsaW1pdHMiOlt7InRpZXIiOiJkZXZlbG9wZXIvc2lsdmVyIiwidHlwZSI6InRocm90dGxpbmcifSx7ImNpZHJzIjpbIjEzLjQ4LjExMi4xNzciXSwidHlwZSI6ImNsaWVudCJ9XX0.TCdFwamnQnl-mrCP498nD9kRfEis6OTK-8PI5HwObNBsfCw1s13L3SePrcdwOAzFoVHzR_nPeXfYv90hK2aI7g
logging.level.com.example.clashwartrackerbackend=INFO
EOF

echo "✅ Build and setup completed successfully!"
"@

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build completed successfully!" -ForegroundColor Green
    
    # Clean up
    Remove-Item $zipPath -Force
    
    Write-Host ""
    Write-Host "🔧 Now configuring services..." -ForegroundColor Blue
    & ".\configure-ec2-app.ps1"
}
else {
    Write-Host "Build failed" -ForegroundColor Red
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
}

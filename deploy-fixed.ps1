# Fixed Deployment Script for Clash War Tracker
param(
    [string]$ElasticIP = "13.48.112.177",
    [string]$KeyPath = "F:\GITHUB\track_clash\myclashkey.pem"
)

Write-Host "Deploying Clash War Tracker to EC2..." -ForegroundColor Green
Write-Host "Target: $ElasticIP" -ForegroundColor Cyan

# Test SSH connection
Write-Host "Testing SSH connection..." -ForegroundColor Blue
$testResult = ssh -i "$KeyPath" -o ConnectTimeout=10 -o StrictHostKeyChecking=no ubuntu@$ElasticIP "whoami" 2>$null

if ($testResult -ne "ubuntu") {
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

Compress-Archive -Path "src", "pom.xml", "clash-war-tracker-frontend" -DestinationPath $zipPath -Force

Write-Host "Uploading source to EC2..." -ForegroundColor Blue
scp -i "$KeyPath" $zipPath ubuntu@${ElasticIP}:/tmp/

Write-Host "Building and configuring on EC2..." -ForegroundColor Blue

# Create a proper shell script file locally first
$shellScript = @'
#!/bin/bash
set -e

echo "Starting deployment process..."

# Update system and install prerequisites
sudo apt update -y
sudo apt install -y default-jdk maven nodejs npm postgresql postgresql-contrib nginx unzip

# Extract source
cd /tmp
unzip -o clash-tracker-source.zip
ls -la

# Build Spring Boot application
echo "Building Spring Boot JAR..."
mvn clean package -DskipTests
if [ $? -ne 0 ]; then
    echo "Maven build failed"
    exit 1
fi

# Build frontend
echo "Building React frontend..."
cd clash-war-tracker-frontend
npm install
npm run build
if [ $? -ne 0 ]; then
    echo "Frontend build failed"
    exit 1
fi
cd ..

# Setup application directories
echo "Setting up application..."
sudo mkdir -p /opt/clash-tracker/{app,frontend,config,logs}
sudo cp target/*.jar /opt/clash-tracker/app/clash-war-tracker-backend.jar
sudo cp -r clash-war-tracker-frontend/dist/* /opt/clash-tracker/frontend/

# Create application user
sudo useradd -r -s /bin/false clash-tracker 2>/dev/null || true
sudo chown -R clash-tracker:clash-tracker /opt/clash-tracker

# Setup PostgreSQL
echo "Setting up PostgreSQL..."
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database and user
sudo -u postgres psql -c "CREATE DATABASE clash_tracker;" 2>/dev/null || true
sudo -u postgres psql -c "CREATE USER clash_tracker_user WITH PASSWORD 'verma2017';" 2>/dev/null || true
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE clash_tracker TO clash_tracker_user;" 2>/dev/null || true

echo "Deployment completed successfully!"
'@

# Write shell script to temp file
$shellScript | Out-File -FilePath "deploy-script.sh" -Encoding UTF8 -NoNewline

# Upload and execute the shell script
Write-Host "Uploading deployment script..." -ForegroundColor Blue
scp -i "$KeyPath" "deploy-script.sh" ubuntu@${ElasticIP}:/tmp/

Write-Host "Executing deployment script..." -ForegroundColor Blue
ssh -i "$KeyPath" ubuntu@$ElasticIP "chmod +x /tmp/deploy-script.sh && /tmp/deploy-script.sh"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Build phase completed successfully!" -ForegroundColor Green
    
    # Now configure services
    Write-Host "Configuring services..." -ForegroundColor Blue
    
    $configScript = @'
#!/bin/bash
set -e

# Create application configuration
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

# Create systemd service for backend
sudo tee /etc/systemd/system/clash-tracker-backend.service > /dev/null << 'EOF'
[Unit]
Description=Clash War Tracker Backend
After=postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=clash-tracker
Group=clash-tracker
WorkingDirectory=/opt/clash-tracker/app
ExecStart=/usr/bin/java -jar -Dspring.profiles.active=prod -Dspring.config.location=/opt/clash-tracker/config/application-prod.properties /opt/clash-tracker/app/clash-war-tracker-backend.jar
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
Environment=JAVA_OPTS="-Xms256m -Xmx512m"

[Install]
WantedBy=multi-user.target
EOF

# Install serve for frontend
sudo npm install -g serve

# Create systemd service for frontend
sudo tee /etc/systemd/system/clash-tracker-frontend.service > /dev/null << 'EOF'
[Unit]
Description=Clash War Tracker Frontend
After=clash-tracker-backend.service

[Service]
Type=simple
User=clash-tracker
Group=clash-tracker
WorkingDirectory=/opt/clash-tracker/frontend
ExecStart=/usr/bin/npx serve -s . -l 3000
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Configure Nginx
sudo tee /etc/nginx/sites-available/clash-tracker > /dev/null << 'EOF'
server {
    listen 80 default_server;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location /api/ {
        proxy_pass http://localhost:8080/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE' always;
        add_header 'Access-Control-Allow-Headers' 'Origin, Content-Type, Accept, Authorization' always;
    }
}
EOF

# Enable nginx site
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/clash-tracker /etc/nginx/sites-enabled/
sudo nginx -t

# Reload systemd and enable services
sudo systemctl daemon-reload
sudo systemctl enable clash-tracker-backend
sudo systemctl enable clash-tracker-frontend
sudo systemctl enable nginx

# Start services
echo "Starting services..."
sudo systemctl restart postgresql
sudo systemctl start clash-tracker-backend
sleep 15
sudo systemctl start clash-tracker-frontend
sudo systemctl restart nginx

echo "Services started successfully!"
'@

    # Write config script
    $configScript | Out-File -FilePath "config-script.sh" -Encoding UTF8 -NoNewline
    
    # Upload and execute config script
    scp -i "$KeyPath" "config-script.sh" ubuntu@${ElasticIP}:/tmp/
    ssh -i "$KeyPath" ubuntu@$ElasticIP "chmod +x /tmp/config-script.sh && /tmp/config-script.sh"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Deployment completed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Your application should now be available at:" -ForegroundColor Yellow
        Write-Host "   Frontend: http://$ElasticIP" -ForegroundColor Cyan
        Write-Host "   Backend:  http://${ElasticIP}:8080" -ForegroundColor Cyan
        Write-Host "   Health:   http://${ElasticIP}:8080/api/health" -ForegroundColor Cyan
    }
    
    # Clean up
    Remove-Item "config-script.sh" -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "Build phase failed" -ForegroundColor Red
}

# Clean up
Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
Remove-Item "deploy-script.sh" -Force -ErrorAction SilentlyContinue

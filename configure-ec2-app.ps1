# Configure and Start Clash War Tracker on EC2
param(
    [string]$ElasticIP = "13.48.112.177",
    [string]$KeyPath = "F:\GITHUB\track_clash\myclashkey.pem"
)

Write-Host "⚙️ Configuring Clash War Tracker on EC2..." -ForegroundColor Green

$configCommands = @"
# Create application configuration
sudo mkdir -p /opt/clash-tracker/config

# Create production application.properties
sudo tee /opt/clash-tracker/config/application-prod.properties > /dev/null << 'EOF'
# Production Configuration for AWS EC2
server.port=8080

# Database Configuration (Local PostgreSQL)
spring.datasource.url=jdbc:postgresql://localhost:5432/clash_tracker
spring.datasource.username=clash_tracker_user
spring.datasource.password=verma2017
spring.datasource.driver-class-name=org.postgresql.Driver

spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=false
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect

# Connection pool settings
spring.datasource.hikari.maximum-pool-size=20
spring.datasource.hikari.minimum-idle=5

# Clash of Clans API Configuration
clash.api.key=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiIsImtpZCI6IjI4YTMxOGY3LTAwMDAtYTFlYi03ZmExLTJjNzQzM2M2Y2NhNSJ9.eyJpc3MiOiJzdXBlcmNlbGwiLCJhdWQiOiJzdXBlcmNlbGw6Z2FtZWFwaSIsImp0aSI6IjczOTczYjAwLWY0MzUtNDA3OC1hYmUwLTZkMmNkYWE1MTFiNyIsImlhdCI6MTc1OTM4MzM2Niwic3ViIjoiZGV2ZWxvcGVyLzA3MzMzZTY3LTA4NTEtNTk5Ny1iZWEyLTA5ZDY2MjBlMDhiOCIsInNjb3BlcyI6WyJjbGFzaCJdLCJsaW1pdHMiOlt7InRpZXIiOiJkZXZlbG9wZXIvc2lsdmVyIiwidHlwZSI6InRocm90dGxpbmcifSx7ImNpZHJzIjpbIjEzLjQ4LjExMi4xNzciXSwidHlwZSI6ImNsaWVudCJ9XX0.TCdFwamnQnl-mrCP498nD9kRfEis6OTK-8PI5HwObNBsfCw1s13L3SePrcdwOAzFoVHzR_nPeXfYv90hK2aI7g

# Logging
logging.level.com.example.clashwartrackerbackend=INFO
logging.file.name=/opt/clash-tracker/logs/application.log
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

# Resource limits
LimitNOFILE=65536

# Environment
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
ExecStart=/usr/bin/npx serve -s dist -l 3000
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Configure Nginx
sudo tee /etc/nginx/conf.d/clash-tracker.conf > /dev/null << 'EOF'
server {
    listen 80 default_server;
    server_name _;

    # Frontend (React app)
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }

    # Backend API
    location /api/ {
        proxy_pass http://localhost:8080/api/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # CORS headers
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE' always;
        add_header 'Access-Control-Allow-Headers' 'Origin, Content-Type, Accept, Authorization' always;
    }
}
EOF

# Remove default nginx config
sudo rm -f /etc/nginx/conf.d/default.conf

# Set permissions
sudo chown -R clash-tracker:clash-tracker /opt/clash-tracker
sudo mkdir -p /opt/clash-tracker/logs

# Reload systemd and enable services
sudo systemctl daemon-reload
sudo systemctl enable clash-tracker-backend
sudo systemctl enable clash-tracker-frontend
sudo systemctl restart nginx

# Start services
echo "Starting PostgreSQL..."
sudo systemctl start postgresql

echo "Starting backend..."
sudo systemctl start clash-tracker-backend

echo "Waiting for backend to start..."
sleep 15

echo "Starting frontend..."
sudo systemctl start clash-tracker-frontend

echo "✅ Configuration complete!"
echo ""
echo "📊 Service Status:"
sudo systemctl status clash-tracker-backend --no-pager -l
echo ""
sudo systemctl status clash-tracker-frontend --no-pager -l
echo ""
sudo systemctl status nginx --no-pager -l
"@

Write-Host "🔧 Configuring services on EC2..." -ForegroundColor Blue
ssh -i "$KeyPath" ec2-user@$ElasticIP $configCommands

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Configuration completed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🌐 Your application should now be available at:" -ForegroundColor Yellow
    Write-Host "   Frontend: http://$ElasticIP" -ForegroundColor Cyan
    Write-Host "   Backend:  http://${ElasticIP}:8080" -ForegroundColor Cyan
    Write-Host "   Health:   http://${ElasticIP}:8080/api/health" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🧪 Test the deployment:" -ForegroundColor Yellow
    Write-Host "   .\test-deployment.ps1" -ForegroundColor White
}
else {
    Write-Host "❌ Configuration failed. Check the output above." -ForegroundColor Red
}

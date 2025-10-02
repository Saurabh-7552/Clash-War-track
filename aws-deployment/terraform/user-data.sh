#!/bin/bash

# User Data Script for Clash War Tracker EC2 Instance
# This script runs when the instance first starts

set -e

# Update system
yum update -y

# Install required packages
yum install -y docker git java-17-amazon-corretto-devel postgresql15 nginx

# Start and enable Docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Node.js 18
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Create application directory
mkdir -p /opt/clash-tracker
cd /opt/clash-tracker

# Create application user
useradd -r -s /bin/false clash-tracker
chown -R clash-tracker:clash-tracker /opt/clash-tracker

# Clone the repository (you'll need to make it public or use deploy keys)
# git clone https://github.com/YOUR_USERNAME/track_clash.git .

# Create environment file
cat > /opt/clash-tracker/.env << EOF
# Database Configuration
DB_HOST=${db_host}
DB_USERNAME=${db_username}
DB_PASSWORD=${db_password}
DB_NAME=clash_tracker

# Clash of Clans API
CLASH_API_KEY=${clash_api_key}

# Application Configuration
SERVER_PORT=8080
FRONTEND_PORT=5173
EOF

# Create application.properties for production
mkdir -p /opt/clash-tracker/src/main/resources
cat > /opt/clash-tracker/application-prod.properties << EOF
# Production Configuration
server.port=8080

# Database Configuration
spring.datasource.url=jdbc:postgresql://${db_host}:5432/clash_tracker
spring.datasource.username=${db_username}
spring.datasource.password=${db_password}
spring.datasource.driver-class-name=org.postgresql.Driver

spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=false
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect
spring.jpa.properties.hibernate.format_sql=false

# Connection pool settings
spring.datasource.hikari.maximum-pool-size=20
spring.datasource.hikari.minimum-idle=10
spring.datasource.hikari.connection-timeout=20000
spring.datasource.hikari.idle-timeout=300000

# Clash of Clans API Configuration
clash.api.key=${clash_api_key}

# Logging
logging.level.com.example.clashwartrackerbackend=INFO
logging.level.okhttp3=WARN
EOF

# Create Docker Compose file
cat > /opt/clash-tracker/docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: clash-tracker-db
    environment:
      POSTGRES_DB: clash_tracker
      POSTGRES_USER: ${DB_USERNAME}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-db.sql:/docker-entrypoint-initdb.d/init-db.sql
    ports:
      - "5432:5432"
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USERNAME}"]
      interval: 30s
      timeout: 10s
      retries: 3

  backend:
    build:
      context: .
      dockerfile: Dockerfile.backend
    container_name: clash-tracker-backend
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - DB_HOST=postgres
      - DB_USERNAME=${DB_USERNAME}
      - DB_PASSWORD=${DB_PASSWORD}
      - CLASH_API_KEY=${CLASH_API_KEY}
    ports:
      - "8080:8080"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  frontend:
    build:
      context: .
      dockerfile: Dockerfile.frontend
    container_name: clash-tracker-frontend
    depends_on:
      - backend
    ports:
      - "80:80"
    restart: unless-stopped

volumes:
  postgres_data:
EOF

# Create database initialization script
cat > /opt/clash-tracker/init-db.sql << 'EOF'
-- Initialize Clash Tracker Database
CREATE DATABASE IF NOT EXISTS clash_tracker;

-- Create user if not exists (PostgreSQL syntax)
DO
$do$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE  rolname = 'clash_tracker_user') THEN
      
      CREATE ROLE clash_tracker_user LOGIN PASSWORD 'secure_password_2024';
   END IF;
END
$do$;

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE clash_tracker TO clash_tracker_user;
EOF

# Create systemd service for the application
cat > /etc/systemd/system/clash-tracker.service << 'EOF'
[Unit]
Description=Clash War Tracker Application
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/clash-tracker
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0
User=clash-tracker
Group=clash-tracker

[Install]
WantedBy=multi-user.target
EOF

# Configure Nginx as reverse proxy
cat > /etc/nginx/conf.d/clash-tracker.conf << 'EOF'
server {
    listen 80;
    server_name _;

    # Frontend (React app)
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Backend API
    location /api/ {
        proxy_pass http://localhost:8080/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS headers
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE' always;
        add_header 'Access-Control-Allow-Headers' 'Origin, Content-Type, Accept, Authorization' always;
        
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*';
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE';
            add_header 'Access-Control-Allow-Headers' 'Origin, Content-Type, Accept, Authorization';
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }
    }
}
EOF

# Set permissions
chown -R clash-tracker:clash-tracker /opt/clash-tracker
chmod +x /opt/clash-tracker

# Enable and start services
systemctl enable nginx
systemctl start nginx
systemctl enable clash-tracker

# Create deployment script
cat > /opt/clash-tracker/deploy.sh << 'EOF'
#!/bin/bash
set -e

echo "🚀 Deploying Clash War Tracker..."

# Pull latest code
git pull origin master

# Build and restart services
docker-compose down
docker-compose build --no-cache
docker-compose up -d

echo "✅ Deployment complete!"
echo "🌐 Application available at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
EOF

chmod +x /opt/clash-tracker/deploy.sh

# Log completion
echo "✅ EC2 instance setup completed at $(date)" >> /var/log/clash-tracker-setup.log
echo "🌐 Elastic IP: 13.48.112.177" >> /var/log/clash-tracker-setup.log
echo "📝 Next steps: Upload application code and run deployment" >> /var/log/clash-tracker-setup.log

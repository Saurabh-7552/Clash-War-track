#!/bin/bash

# User Data Script for Clash War Tracker EC2 Instance (JAR Deployment)
# Customized for: t3.micro, Amazon Linux 2, JAR deployment, Local PostgreSQL

set -e

# Log all output
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "🚀 Starting Clash War Tracker EC2 setup..."
echo "Instance Type: t3.micro"
echo "OS: Amazon Linux 2"
echo "Deployment: JAR File"
echo "Database: Local PostgreSQL"
echo "Domain: clashtrack.ai"

# Update system
yum update -y

# Install Java 17 (Amazon Corretto)
yum install -y java-17-amazon-corretto-devel

# Install PostgreSQL 15
yum install -y postgresql15-server postgresql15

# Install Node.js 18 for frontend
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Install Nginx for reverse proxy
yum install -y nginx

# Install other utilities
yum install -y git wget curl unzip htop

# Initialize PostgreSQL
postgresql-setup --initdb
systemctl enable postgresql
systemctl start postgresql

# Configure PostgreSQL
sudo -u postgres psql << EOF
CREATE DATABASE clash_tracker;
CREATE USER clash_tracker_user WITH PASSWORD 'verma2017';
GRANT ALL PRIVILEGES ON DATABASE clash_tracker TO clash_tracker_user;
ALTER USER postgres PASSWORD 'verma2017';
\q
EOF

# Configure PostgreSQL for local connections
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = 'localhost'/" /var/lib/pgsql/data/postgresql.conf
echo "host all all 127.0.0.1/32 md5" >> /var/lib/pgsql/data/pg_hba.conf
systemctl restart postgresql

# Create application user and directories
useradd -r -s /bin/bash clash-tracker
mkdir -p /opt/clash-tracker/{app,logs,config}
chown -R clash-tracker:clash-tracker /opt/clash-tracker

# Create application.properties for production
cat > /opt/clash-tracker/config/application-prod.properties << EOF
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
spring.jpa.properties.hibernate.format_sql=false

# Connection pool settings
spring.datasource.hikari.maximum-pool-size=20
spring.datasource.hikari.minimum-idle=5
spring.datasource.hikari.connection-timeout=20000
spring.datasource.hikari.idle-timeout=300000

# Clash of Clans API Configuration
clash.api.key=${clash_api_key}

# Logging Configuration
logging.level.com.example.clashwartrackerbackend=INFO
logging.level.okhttp3=WARN
logging.file.name=/opt/clash-tracker/logs/application.log
logging.file.max-size=10MB
logging.file.max-history=10
EOF

# Create systemd service for Spring Boot application
cat > /etc/systemd/system/clash-tracker-backend.service << EOF
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
SyslogIdentifier=clash-tracker-backend

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096

# Environment
Environment=JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC"

[Install]
WantedBy=multi-user.target
EOF

# Create systemd service for frontend (Node.js serve)
cat > /etc/systemd/system/clash-tracker-frontend.service << EOF
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
SyslogIdentifier=clash-tracker-frontend

[Install]
WantedBy=multi-user.target
EOF

# Configure Nginx as reverse proxy with SSL support
cat > /etc/nginx/conf.d/clashtrack.conf << EOF
# HTTP to HTTPS redirect
server {
    listen 80;
    server_name clashtrack.ai www.clashtrack.ai 13.48.112.177;
    return 301 https://\$server_name\$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name clashtrack.ai www.clashtrack.ai;

    # SSL Configuration (will be configured later with Let's Encrypt)
    ssl_certificate /etc/ssl/certs/clashtrack.ai.crt;
    ssl_certificate_key /etc/ssl/private/clashtrack.ai.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Frontend (React app)
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
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
        add_header 'Access-Control-Allow-Origin' 'https://clashtrack.ai' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE' always;
        add_header 'Access-Control-Allow-Headers' 'Origin, Content-Type, Accept, Authorization' always;
        
        if (\$request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' 'https://clashtrack.ai';
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE';
            add_header 'Access-Control-Allow-Headers' 'Origin, Content-Type, Accept, Authorization';
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }
    }
}

# Fallback server for direct IP access
server {
    listen 80 default_server;
    listen 443 ssl default_server;
    server_name 13.48.112.177;

    # Self-signed certificate for IP access
    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;

    location / {
        return 301 https://clashtrack.ai\$request_uri;
    }
}
EOF

# Remove default Nginx configuration
rm -f /etc/nginx/conf.d/default.conf

# Create self-signed certificate for initial setup
mkdir -p /etc/ssl/certs /etc/ssl/private
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=13.48.112.177"

# Create placeholder SSL certificates for domain
cp /etc/ssl/certs/nginx-selfsigned.crt /etc/ssl/certs/clashtrack.ai.crt
cp /etc/ssl/private/nginx-selfsigned.key /etc/ssl/private/clashtrack.ai.key

# Install Certbot for Let's Encrypt SSL
yum install -y certbot python3-certbot-nginx

# Create deployment script
cat > /opt/clash-tracker/deploy.sh << 'EOF'
#!/bin/bash
set -e

echo "🚀 Deploying Clash War Tracker..."

# Stop services
sudo systemctl stop clash-tracker-backend clash-tracker-frontend

# Backup current deployment
if [ -f /opt/clash-tracker/app/clash-war-tracker-backend.jar ]; then
    cp /opt/clash-tracker/app/clash-war-tracker-backend.jar /opt/clash-tracker/app/clash-war-tracker-backend.jar.backup
fi

# Deploy new JAR (assuming it's uploaded to /tmp/)
if [ -f /tmp/clash-war-tracker-backend.jar ]; then
    cp /tmp/clash-war-tracker-backend.jar /opt/clash-tracker/app/
    chown clash-tracker:clash-tracker /opt/clash-tracker/app/clash-war-tracker-backend.jar
fi

# Deploy frontend (assuming it's uploaded to /tmp/)
if [ -d /tmp/frontend-dist ]; then
    rm -rf /opt/clash-tracker/frontend/dist
    cp -r /tmp/frontend-dist /opt/clash-tracker/frontend/dist
    chown -R clash-tracker:clash-tracker /opt/clash-tracker/frontend
fi

# Start services
sudo systemctl start clash-tracker-backend
sleep 10
sudo systemctl start clash-tracker-frontend

# Check status
sudo systemctl status clash-tracker-backend --no-pager
sudo systemctl status clash-tracker-frontend --no-pager

echo "✅ Deployment complete!"
echo "🌐 Application available at: https://clashtrack.ai"
EOF

chmod +x /opt/clash-tracker/deploy.sh

# Create SSL setup script
cat > /opt/clash-tracker/setup-ssl.sh << 'EOF'
#!/bin/bash
set -e

echo "🔒 Setting up SSL certificate for clashtrack.ai..."

# Stop Nginx temporarily
sudo systemctl stop nginx

# Obtain SSL certificate
sudo certbot certonly --standalone \
    -d clashtrack.ai \
    -d www.clashtrack.ai \
    --email admin@clashtrack.ai \
    --agree-tos \
    --non-interactive

# Update Nginx configuration to use real certificates
sudo sed -i 's|/etc/ssl/certs/clashtrack.ai.crt|/etc/letsencrypt/live/clashtrack.ai/fullchain.pem|' /etc/nginx/conf.d/clashtrack.conf
sudo sed -i 's|/etc/ssl/private/clashtrack.ai.key|/etc/letsencrypt/live/clashtrack.ai/privkey.pem|' /etc/nginx/conf.d/clashtrack.conf

# Start Nginx
sudo systemctl start nginx

# Set up auto-renewal
echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -

echo "✅ SSL certificate setup complete!"
EOF

chmod +x /opt/clash-tracker/setup-ssl.sh

# Create monitoring script
cat > /opt/clash-tracker/monitor.sh << 'EOF'
#!/bin/bash

echo "📊 Clash War Tracker Status"
echo "=========================="

# Check services
echo "🔧 Services Status:"
sudo systemctl is-active postgresql || echo "❌ PostgreSQL not running"
sudo systemctl is-active clash-tracker-backend || echo "❌ Backend not running"
sudo systemctl is-active clash-tracker-frontend || echo "❌ Frontend not running"
sudo systemctl is-active nginx || echo "❌ Nginx not running"

# Check ports
echo ""
echo "🌐 Port Status:"
netstat -tlnp | grep -E ':80|:443|:8080|:3000|:5432' || echo "No services listening"

# Check disk space
echo ""
echo "💾 Disk Usage:"
df -h /

# Check memory
echo ""
echo "🧠 Memory Usage:"
free -h

# Check logs for errors
echo ""
echo "📝 Recent Errors:"
sudo journalctl -u clash-tracker-backend --since "1 hour ago" | grep -i error | tail -5 || echo "No recent errors"
EOF

chmod +x /opt/clash-tracker/monitor.sh

# Set permissions
chown -R clash-tracker:clash-tracker /opt/clash-tracker
chmod 755 /opt/clash-tracker

# Enable services
systemctl enable postgresql
systemctl enable nginx
systemctl enable clash-tracker-backend
systemctl enable clash-tracker-frontend

# Start Nginx
systemctl start nginx

# Create welcome message
cat > /etc/motd << 'EOF'
🚀 Clash War Tracker EC2 Instance
================================

Instance Details:
- Type: t3.micro
- OS: Amazon Linux 2
- Elastic IP: 13.48.112.177
- Domain: clashtrack.ai

Services:
- PostgreSQL: localhost:5432
- Backend: localhost:8080
- Frontend: localhost:3000
- Nginx: 80, 443

Useful Commands:
- Deploy app: /opt/clash-tracker/deploy.sh
- Setup SSL: /opt/clash-tracker/setup-ssl.sh
- Monitor: /opt/clash-tracker/monitor.sh
- Logs: journalctl -u clash-tracker-backend -f

Next Steps:
1. Upload JAR file and frontend build
2. Run deployment script
3. Setup SSL certificate
4. Point domain to this IP

EOF

# Log completion
echo "✅ EC2 instance setup completed at $(date)" >> /var/log/clash-tracker-setup.log
echo "🌐 Elastic IP: 13.48.112.177" >> /var/log/clash-tracker-setup.log
echo "🌍 Domain: clashtrack.ai" >> /var/log/clash-tracker-setup.log
echo "📝 Next: Upload application files and run deployment" >> /var/log/clash-tracker-setup.log

echo "🎉 Clash War Tracker EC2 setup complete!"

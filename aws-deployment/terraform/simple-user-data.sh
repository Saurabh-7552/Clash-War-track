#!/bin/bash

# Simple User Data Script for Clash War Tracker EC2 Instance
set -e

# Update system
yum update -y

# Install Java 17
yum install -y java-17-amazon-corretto-devel

# Install PostgreSQL 15
yum install -y postgresql15-server postgresql15

# Install Node.js 18
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Install Nginx
yum install -y nginx

# Install utilities
yum install -y git wget curl unzip

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
mkdir -p /opt/clash-tracker/{app,logs,config,frontend}
chown -R clash-tracker:clash-tracker /opt/clash-tracker

# Enable services
systemctl enable postgresql
systemctl enable nginx
systemctl start nginx

# Create setup completion marker
echo "EC2 setup completed at $(date)" > /var/log/clash-tracker-setup.log

echo "✅ Basic EC2 setup complete!"

#!/bin/bash

# Setup script for AWS deployment
# This script helps you configure the deployment

set -e

echo "🚀 Clash War Tracker - AWS Deployment Setup"
echo "============================================"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Collect required information
echo ""
print_info "I need some information to set up your AWS deployment:"
echo ""

# AWS Key Pair
read -p "🔑 Enter your AWS Key Pair name (e.g., my-key-pair): " KEY_PAIR_NAME
if [ -z "$KEY_PAIR_NAME" ]; then
    print_warning "Key pair name is required. Please create one in AWS EC2 console first."
    exit 1
fi

# Clash API Key
echo ""
print_warning "⚠️  IMPORTANT: You need to create a Clash of Clans API key for IP: 13.48.112.177"
echo "   1. Go to: https://developer.clashofclans.com/"
echo "   2. Create new API key"
echo "   3. Use IP: 13.48.112.177"
echo "   4. Copy the API key"
echo ""
read -p "🎮 Enter your Clash of Clans API key: " CLASH_API_KEY
if [ -z "$CLASH_API_KEY" ]; then
    print_warning "API key is required. Please create one first."
    exit 1
fi

# Database password
echo ""
read -p "🔒 Enter database password (or press Enter for default 'verma2017'): " DB_PASSWORD
if [ -z "$DB_PASSWORD" ]; then
    DB_PASSWORD="verma2017"
fi

# Create configuration files
print_info "Creating configuration files..."

# Update deployment script
sed -i.bak "s/KEY_PAIR_NAME=\"\"/KEY_PAIR_NAME=\"$KEY_PAIR_NAME\"/" aws-deployment/deploy-to-aws.sh
sed -i.bak "s/CLASH_API_KEY=\"\"/CLASH_API_KEY=\"$CLASH_API_KEY\"/" aws-deployment/deploy-to-aws.sh

# Create Terraform variables
cat > aws-deployment/terraform/terraform.tfvars << EOF
# AWS Configuration
aws_region = "eu-north-1"
elastic_ip = "13.48.112.177"

# EC2 Configuration
instance_type = "t3.micro"
key_pair_name = "$KEY_PAIR_NAME"

# Application Configuration
clash_api_key = "$CLASH_API_KEY"

# Database Configuration
create_rds = false
db_host = "localhost"
db_username = "postgres"
db_password = "$DB_PASSWORD"
EOF

# Update application properties for production
cat > src/main/resources/application-prod.properties << EOF
# Production Configuration for AWS
server.port=8080

# Database Configuration
spring.datasource.url=jdbc:postgresql://localhost:5432/clash_tracker
spring.datasource.username=postgres
spring.datasource.password=$DB_PASSWORD
spring.datasource.driver-class-name=org.postgresql.Driver

spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=false
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect

# Connection pool settings
spring.datasource.hikari.maximum-pool-size=20
spring.datasource.hikari.minimum-idle=10

# Clash of Clans API Configuration
clash.api.key=$CLASH_API_KEY

# Logging
logging.level.com.example.clashwartrackerbackend=INFO
EOF

# Make scripts executable
chmod +x aws-deployment/deploy-to-aws.sh

print_success "Configuration completed!"
echo ""
echo "📋 Configuration Summary:"
echo "   Elastic IP: 13.48.112.177"
echo "   Key Pair: $KEY_PAIR_NAME"
echo "   API Key: ${CLASH_API_KEY:0:20}..."
echo "   Database Password: [HIDDEN]"
echo ""
echo "🚀 Next Steps:"
echo "   1. Ensure AWS CLI is configured: aws configure"
echo "   2. Install Terraform: https://terraform.io"
echo "   3. Run deployment: ./aws-deployment/deploy-to-aws.sh"
echo ""
echo "📖 For detailed instructions, see: aws-deployment/README.md"

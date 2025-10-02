#!/bin/bash

# AWS Deployment Script for Clash War Tracker
# This script deploys the application to AWS EC2 with Elastic IP

set -e

echo "🚀 Starting AWS Deployment for Clash War Tracker"
echo "================================================"

# Configuration
ELASTIC_IP="13.48.112.177"
AWS_REGION="eu-north-1"
KEY_PAIR_NAME=""  # You need to set this
CLASH_API_KEY=""  # You need to set this

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Run 'aws configure' first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Validate configuration
validate_config() {
    print_status "Validating configuration..."
    
    if [ -z "$KEY_PAIR_NAME" ]; then
        print_error "KEY_PAIR_NAME is not set. Please update the script."
        exit 1
    fi
    
    if [ -z "$CLASH_API_KEY" ]; then
        print_error "CLASH_API_KEY is not set. Please create API key for IP $ELASTIC_IP first."
        exit 1
    fi
    
    print_success "Configuration validation passed"
}

# Create Terraform variables file
create_terraform_vars() {
    print_status "Creating Terraform variables file..."
    
    cat > aws-deployment/terraform/terraform.tfvars << EOF
# AWS Configuration
aws_region = "$AWS_REGION"
elastic_ip = "$ELASTIC_IP"

# EC2 Configuration
instance_type = "t3.micro"
key_pair_name = "$KEY_PAIR_NAME"

# Application Configuration
clash_api_key = "$CLASH_API_KEY"

# Database Configuration
create_rds = false  # Set to true if you want RDS
db_host = "localhost"
db_username = "postgres"
db_password = "verma2017"
EOF
    
    print_success "Terraform variables file created"
}

# Deploy infrastructure
deploy_infrastructure() {
    print_status "Deploying infrastructure with Terraform..."
    
    cd aws-deployment/terraform
    
    # Initialize Terraform
    terraform init
    
    # Plan deployment
    terraform plan -var-file="terraform.tfvars"
    
    # Ask for confirmation
    echo ""
    read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Apply deployment
        terraform apply -var-file="terraform.tfvars" -auto-approve
        print_success "Infrastructure deployed successfully"
    else
        print_warning "Deployment cancelled"
        exit 0
    fi
    
    cd ../..
}

# Upload application code
upload_code() {
    print_status "Uploading application code to EC2..."
    
    # Create deployment package
    tar -czf clash-tracker-app.tar.gz \
        --exclude='node_modules' \
        --exclude='target' \
        --exclude='.git' \
        --exclude='aws-deployment/terraform/.terraform' \
        .
    
    # Upload to EC2
    scp -i ~/.ssh/$KEY_PAIR_NAME.pem \
        clash-tracker-app.tar.gz \
        ec2-user@$ELASTIC_IP:/tmp/
    
    # Extract and setup on EC2
    ssh -i ~/.ssh/$KEY_PAIR_NAME.pem ec2-user@$ELASTIC_IP << 'EOF'
        sudo su - clash-tracker
        cd /opt/clash-tracker
        sudo tar -xzf /tmp/clash-tracker-app.tar.gz -C /opt/clash-tracker --strip-components=1
        sudo chown -R clash-tracker:clash-tracker /opt/clash-tracker
        
        # Copy Docker files to correct location
        cp aws-deployment/Dockerfile.* .
        cp aws-deployment/docker-compose.yml .
        cp aws-deployment/nginx.conf .
        
        # Start the application
        sudo systemctl start clash-tracker
        sudo systemctl enable clash-tracker
EOF
    
    # Cleanup
    rm clash-tracker-app.tar.gz
    
    print_success "Application code uploaded and deployed"
}

# Test deployment
test_deployment() {
    print_status "Testing deployment..."
    
    # Wait for services to start
    sleep 30
    
    # Test backend health
    if curl -f "http://$ELASTIC_IP:8080/api/health" &> /dev/null; then
        print_success "Backend is responding"
    else
        print_warning "Backend health check failed"
    fi
    
    # Test frontend
    if curl -f "http://$ELASTIC_IP" &> /dev/null; then
        print_success "Frontend is responding"
    else
        print_warning "Frontend health check failed"
    fi
    
    print_success "Deployment testing completed"
}

# Main deployment process
main() {
    echo "Starting deployment process..."
    echo "Elastic IP: $ELASTIC_IP"
    echo "AWS Region: $AWS_REGION"
    echo ""
    
    check_prerequisites
    validate_config
    create_terraform_vars
    deploy_infrastructure
    upload_code
    test_deployment
    
    echo ""
    print_success "🎉 Deployment completed successfully!"
    echo ""
    echo "📋 Access Information:"
    echo "   Frontend: http://$ELASTIC_IP"
    echo "   Backend:  http://$ELASTIC_IP:8080"
    echo "   SSH:      ssh -i ~/.ssh/$KEY_PAIR_NAME.pem ec2-user@$ELASTIC_IP"
    echo ""
    echo "📝 Next Steps:"
    echo "   1. Update your Clash of Clans API key for IP: $ELASTIC_IP"
    echo "   2. Test the application functionality"
    echo "   3. Configure domain name (optional)"
    echo "   4. Set up SSL certificate (optional)"
}

# Run main function
main "$@"

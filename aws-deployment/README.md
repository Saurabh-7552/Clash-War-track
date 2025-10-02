# 🚀 AWS Deployment Guide for Clash War Tracker

## 📋 Prerequisites

### 1. AWS Account Setup
- ✅ **Elastic IP Created**: `13.48.112.177`
- ❓ **EC2 Key Pair**: Create or use existing
- ❓ **AWS CLI Configured**: Run `aws configure`
- ❓ **Terraform Installed**: Download from terraform.io

### 2. Clash of Clans API Key
- ❓ **Create API Key**: Go to https://developer.clashofclans.com/
- ❓ **Use IP**: `13.48.112.177`
- ❓ **Copy API Key**: For configuration

---

## 🛠️ Quick Deployment

### Option A: Automated Deployment (Recommended)

1. **Update Configuration**:
   ```bash
   # Edit aws-deployment/deploy-to-aws.sh
   KEY_PAIR_NAME="your-key-pair-name"
   CLASH_API_KEY="your-api-key-for-13.48.112.177"
   ```

2. **Run Deployment**:
   ```bash
   chmod +x aws-deployment/deploy-to-aws.sh
   ./aws-deployment/deploy-to-aws.sh
   ```

### Option B: Manual Deployment

1. **Configure Terraform**:
   ```bash
   cd aws-deployment/terraform
   
   # Create terraform.tfvars
   cat > terraform.tfvars << EOF
   aws_region = "eu-north-1"
   elastic_ip = "13.48.112.177"
   key_pair_name = "your-key-pair-name"
   clash_api_key = "your-clash-api-key"
   EOF
   ```

2. **Deploy Infrastructure**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Upload Application**:
   ```bash
   # Create package
   tar -czf app.tar.gz --exclude=node_modules --exclude=target .
   
   # Upload to EC2
   scp -i ~/.ssh/your-key.pem app.tar.gz ec2-user@13.48.112.177:/tmp/
   
   # Deploy on EC2
   ssh -i ~/.ssh/your-key.pem ec2-user@13.48.112.177
   sudo su - clash-tracker
   cd /opt/clash-tracker
   tar -xzf /tmp/app.tar.gz
   sudo systemctl start clash-tracker
   ```

---

## 🏗️ Architecture

```
Internet
    ↓
Elastic IP (13.48.112.177)
    ↓
EC2 Instance (t3.micro)
    ├── Nginx (Port 80) → Frontend
    ├── Spring Boot (Port 8080) → Backend
    └── PostgreSQL (Port 5432) → Database
```

---

## 📁 File Structure

```
aws-deployment/
├── terraform/
│   ├── main.tf              # Infrastructure definition
│   ├── variables.tf         # Configuration variables
│   ├── user-data.sh         # EC2 initialization script
│   └── terraform.tfvars     # Your configuration values
├── Dockerfile.backend       # Backend container
├── Dockerfile.frontend      # Frontend container
├── docker-compose.yml       # Multi-container setup
├── nginx.conf              # Reverse proxy configuration
├── deploy-to-aws.sh        # Automated deployment script
└── README.md               # This file
```

---

## ⚙️ Configuration Details

### Required Information:
1. **AWS Key Pair Name**: `your-key-pair-name`
2. **Clash API Key**: Created for IP `13.48.112.177`
3. **Database Password**: Change from default `verma2017`

### Optional Configuration:
- **Instance Type**: Default `t3.micro` (free tier)
- **RDS Database**: Set `create_rds = true` for managed database
- **Custom Domain**: Configure after deployment
- **SSL Certificate**: Use AWS Certificate Manager

---

## 🔧 Post-Deployment Steps

### 1. Verify Deployment
```bash
# Test backend
curl http://13.48.112.177:8080/api/health

# Test frontend
curl http://13.48.112.177

# Check logs
ssh -i ~/.ssh/your-key.pem ec2-user@13.48.112.177
sudo docker logs clash-tracker-backend
sudo docker logs clash-tracker-frontend
```

### 2. Update API Configuration
```bash
# SSH to instance
ssh -i ~/.ssh/your-key.pem ec2-user@13.48.112.177

# Update API key if needed
sudo nano /opt/clash-tracker/.env

# Restart services
sudo systemctl restart clash-tracker
```

### 3. Monitor Application
```bash
# Check service status
sudo systemctl status clash-tracker

# View logs
sudo journalctl -u clash-tracker -f

# Check Docker containers
sudo docker ps
sudo docker logs clash-tracker-backend
```

---

## 🌐 Access Information

After successful deployment:

- **Frontend**: http://13.48.112.177
- **Backend API**: http://13.48.112.177:8080
- **Health Check**: http://13.48.112.177:8080/api/health
- **SSH Access**: `ssh -i ~/.ssh/your-key.pem ec2-user@13.48.112.177`

---

## 🔒 Security Considerations

### Production Recommendations:
1. **Change Default Passwords**
2. **Enable HTTPS** with SSL certificate
3. **Restrict Security Groups** to specific IPs
4. **Use AWS Secrets Manager** for sensitive data
5. **Enable CloudWatch Monitoring**
6. **Set up Backup Strategy**

### Security Groups:
- **SSH (22)**: Your IP only
- **HTTP (80)**: 0.0.0.0/0
- **HTTPS (443)**: 0.0.0.0/0
- **Backend (8080)**: Internal only

---

## 🚨 Troubleshooting

### Common Issues:

1. **API Key Issues**:
   ```bash
   # Check current IP matches API key
   curl https://api.ipify.org
   # Should return: 13.48.112.177
   ```

2. **Service Not Starting**:
   ```bash
   # Check logs
   sudo journalctl -u clash-tracker -f
   sudo docker logs clash-tracker-backend
   ```

3. **Database Connection**:
   ```bash
   # Test database
   sudo docker exec -it clash-tracker-db psql -U postgres -d clash_tracker
   ```

4. **Network Issues**:
   ```bash
   # Check security groups
   aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx
   ```

---

## 💰 Cost Estimation

### Monthly AWS Costs (approximate):
- **EC2 t3.micro**: $8.50/month (free tier: $0 for 12 months)
- **Elastic IP**: $3.65/month (free when attached to running instance)
- **EBS Storage (20GB)**: $2.00/month
- **Data Transfer**: ~$1.00/month (first 1GB free)

**Total**: ~$15/month (or $0 with free tier)

---

## 📞 Support

If you encounter issues:

1. **Check Logs**: Always start with application logs
2. **Verify Configuration**: Ensure all variables are set correctly
3. **Test Connectivity**: Use curl to test endpoints
4. **AWS Console**: Check EC2 instance status and security groups

---

## 🎯 Next Steps

After successful deployment:

1. **Test Application**: Verify all features work
2. **Set up Monitoring**: CloudWatch, alerts
3. **Configure Backup**: Database and application data
4. **Domain Setup**: Point domain to Elastic IP
5. **SSL Certificate**: Enable HTTPS
6. **CI/CD Pipeline**: Automate future deployments

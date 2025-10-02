# 🚀 Clash War Tracker - AWS EC2 JAR Deployment Guide

## 📋 Your Configuration Summary

- **Elastic IP**: `13.48.112.177` ✅
- **Instance Type**: `t3.micro` ✅  
- **OS**: Amazon Linux 2 ✅
- **Key Pair**: `myclashkey` ✅
- **Domain**: `clashtrack.ai` ✅
- **Database**: Local PostgreSQL ✅
- **Deployment**: JAR File ✅
- **API Key**: Configured for IP `13.48.112.177` ✅

---

## 🎯 Quick Deployment (3 Steps)

### Step 1: Prerequisites Setup

1. **Install AWS CLI**:
   ```bash
   # Download from: https://aws.amazon.com/cli/
   aws configure
   # Enter your AWS credentials and set region to: eu-north-1
   ```

2. **Install Terraform**:
   ```bash
   # Download from: https://terraform.io/downloads
   # Add to PATH
   ```

3. **Download Key Pair**:
   - Go to AWS Console → EC2 → Key Pairs
   - Download `myclashkey.pem`
   - Place in `~/.ssh/myclashkey.pem`
   - Set permissions: `chmod 400 ~/.ssh/myclashkey.pem`

### Step 2: Deploy to AWS

```bash
# Navigate to project directory
cd F:\GITHUB\track_clash

# Make deployment script executable (Linux/Mac)
chmod +x aws-deployment/jar-deployment/deploy-jar.sh

# Run deployment
./aws-deployment/jar-deployment/deploy-jar.sh
```

### Step 3: Configure Domain

1. **Point Domain to IP**:
   - Go to your domain registrar (where you bought clashtrack.ai)
   - Add A record: `clashtrack.ai` → `13.48.112.177`
   - Add A record: `www.clashtrack.ai` → `13.48.112.177`

2. **Setup SSL Certificate**:
   ```bash
   # After DNS propagation (wait 1-24 hours)
   ssh -i ~/.ssh/myclashkey.pem ec2-user@13.48.112.177
   sudo /opt/clash-tracker/setup-ssl.sh
   ```

---

## 🏗️ What Gets Deployed

### Infrastructure:
- **EC2 Instance**: t3.micro with Elastic IP
- **Security Group**: Ports 22, 80, 443, 8080 open
- **PostgreSQL**: Local database on EC2
- **Nginx**: Reverse proxy with SSL support

### Application Stack:
```
Internet → Nginx (443/80) → React Frontend (3000)
                         → Spring Boot API (8080) → PostgreSQL (5432)
```

### Services Created:
- `clash-tracker-backend.service` - Spring Boot JAR
- `clash-tracker-frontend.service` - React app
- `postgresql.service` - Database
- `nginx.service` - Web server

---

## 📁 Files Created for You

### Terraform Infrastructure:
- `aws-deployment/terraform/main.tf` - AWS resources
- `aws-deployment/terraform/variables.tf` - Configuration
- `aws-deployment/terraform/terraform.tfvars` - Your values

### Deployment Scripts:
- `aws-deployment/jar-deployment/deploy-jar.sh` - Main deployment
- `aws-deployment/jar-deployment/user-data.sh` - EC2 setup

### Server Scripts (Created on EC2):
- `/opt/clash-tracker/deploy.sh` - Deploy new versions
- `/opt/clash-tracker/setup-ssl.sh` - SSL certificate
- `/opt/clash-tracker/monitor.sh` - Health monitoring

---

## 🔧 Manual Deployment (If Automated Fails)

### 1. Deploy Infrastructure:
```bash
cd aws-deployment/terraform
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

### 2. Build Application:
```bash
# Build JAR
./mvnw clean package -DskipTests

# Build Frontend
cd clash-war-tracker-frontend
npm install && npm run build
cd ..
```

### 3. Upload Files:
```bash
# Upload JAR
scp -i ~/.ssh/myclashkey.pem target/*.jar ec2-user@13.48.112.177:/tmp/clash-war-tracker-backend.jar

# Upload Frontend
scp -i ~/.ssh/myclashkey.pem -r clash-war-tracker-frontend/dist ec2-user@13.48.112.177:/tmp/frontend-dist
```

### 4. Deploy on EC2:
```bash
ssh -i ~/.ssh/myclashkey.pem ec2-user@13.48.112.177
sudo /opt/clash-tracker/deploy.sh
```

---

## 🌐 Access After Deployment

### Immediate Access (HTTP):
- **Frontend**: http://13.48.112.177
- **Backend**: http://13.48.112.177:8080
- **Health Check**: http://13.48.112.177:8080/api/health

### After SSL Setup (HTTPS):
- **Production**: https://clashtrack.ai
- **API**: https://clashtrack.ai/api/

---

## 🔍 Testing & Monitoring

### Test API Functionality:
```bash
# Test health endpoint
curl http://13.48.112.177:8080/api/health

# Test Clash API
curl "http://13.48.112.177:8080/api/fetch-currentwar?clanTag=%232GC8P2L88"

# Test leaderboard
curl http://13.48.112.177:8080/api/leaderboard
```

### Monitor Services:
```bash
# SSH to server
ssh -i ~/.ssh/myclashkey.pem ec2-user@13.48.112.177

# Run monitoring script
/opt/clash-tracker/monitor.sh

# Check logs
sudo journalctl -u clash-tracker-backend -f
sudo journalctl -u clash-tracker-frontend -f
```

---

## 🚨 Troubleshooting

### Common Issues:

1. **"Permission denied" for key file**:
   ```bash
   chmod 400 ~/.ssh/myclashkey.pem
   ```

2. **"Connection refused" to EC2**:
   - Check security group allows SSH (port 22)
   - Verify Elastic IP is attached
   - Wait for instance to fully boot (5-10 minutes)

3. **API returns empty array**:
   - Check if API key is correct for IP 13.48.112.177
   - Verify clan tag format (#2GC8P2L88)
   - Check backend logs for errors

4. **Frontend not loading**:
   - Check if frontend service is running
   - Verify Nginx configuration
   - Check port 80/443 in security group

5. **SSL certificate issues**:
   - Ensure domain points to correct IP
   - Wait for DNS propagation (up to 24 hours)
   - Check domain ownership

### Get Help:
```bash
# Check all service status
ssh -i ~/.ssh/myclashkey.pem ec2-user@13.48.112.177 '/opt/clash-tracker/monitor.sh'

# View detailed logs
ssh -i ~/.ssh/myclashkey.pem ec2-user@13.48.112.177 'sudo journalctl -u clash-tracker-backend --since "1 hour ago"'
```

---

## 💰 Cost Breakdown

### Monthly AWS Costs:
- **EC2 t3.micro**: $8.50/month (Free tier: $0 for 12 months)
- **Elastic IP**: $0 (free when attached to running instance)
- **EBS Storage (8GB)**: $0.80/month
- **Data Transfer**: ~$1/month (1GB free)

**Total**: ~$10/month (or $0 with free tier)

---

## 🔄 Future Updates

### Deploy New Version:
```bash
# Build locally
./mvnw clean package -DskipTests
cd clash-war-tracker-frontend && npm run build && cd ..

# Upload and deploy
scp -i ~/.ssh/myclashkey.pem target/*.jar ec2-user@13.48.112.177:/tmp/clash-war-tracker-backend.jar
scp -i ~/.ssh/myclashkey.pem -r clash-war-tracker-frontend/dist ec2-user@13.48.112.177:/tmp/frontend-dist
ssh -i ~/.ssh/myclashkey.pem ec2-user@13.48.112.177 'sudo /opt/clash-tracker/deploy.sh'
```

### Scale Up:
- Change instance type in `terraform.tfvars`
- Run `terraform apply`
- No downtime with Elastic IP

---

## 🎯 Success Checklist

- [ ] AWS CLI configured
- [ ] Terraform installed
- [ ] Key pair downloaded and permissions set
- [ ] Infrastructure deployed
- [ ] Application uploaded and running
- [ ] Health endpoints responding
- [ ] Domain pointing to Elastic IP
- [ ] SSL certificate configured
- [ ] Application accessible at https://clashtrack.ai

**You're ready to deploy! 🚀**

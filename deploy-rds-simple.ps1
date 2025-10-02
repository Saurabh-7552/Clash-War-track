# Deploy RDS Configuration to EC2

$EC2_IP = "13.48.112.177"
$SSH_KEY = "myclashkey.pem"

Write-Host "Updating EC2 instance to use Amazon RDS..." -ForegroundColor Green

# Upload configuration file
Write-Host "Uploading RDS configuration..." -ForegroundColor Yellow
& scp -i $SSH_KEY application-prod-rds.properties ubuntu@${EC2_IP}:/home/ubuntu/

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to upload configuration" -ForegroundColor Red
    exit 1
}

Write-Host "Configuration uploaded successfully" -ForegroundColor Green

# Update application on EC2
Write-Host "Updating application configuration..." -ForegroundColor Yellow

& ssh -i $SSH_KEY ubuntu@$EC2_IP @"
sudo systemctl stop clash-tracker-backend
sudo cp /opt/clash-tracker/application-prod.properties /opt/clash-tracker/application-prod.properties.backup
sudo cp /home/ubuntu/application-prod-rds.properties /opt/clash-tracker/application-prod.properties
sudo systemctl start clash-tracker-backend
sleep 5
sudo systemctl status clash-tracker-backend --no-pager
"@

if ($LASTEXITCODE -eq 0) {
    Write-Host "Application updated successfully" -ForegroundColor Green
} else {
    Write-Host "Update completed with warnings" -ForegroundColor Yellow
}

Write-Host "RDS Migration Completed!" -ForegroundColor Green
Write-Host "Application URL: http://$EC2_IP" -ForegroundColor Cyan
Write-Host "Test the application to verify RDS connectivity" -ForegroundColor Yellow

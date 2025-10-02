# 🔧 Clash of Clans API IP Restriction Solutions

## 🎯 Problem
Your IP address keeps changing, but Clash of Clans API keys are restricted to specific IP addresses.

## 💡 Solutions (Recommended Order)

### 1. 🌐 VPN with Static IP (RECOMMENDED)
**Best for: Development & Testing**

#### Steps:
1. **Get VPN with dedicated IP:**
   - NordVPN (Dedicated IP addon ~$70/year)
   - PureVPN (Dedicated IP ~$35/year)
   - Surfshark (Static IP locations)

2. **Setup Process:**
   ```bash
   # 1. Connect to VPN with static IP
   # 2. Check your IP
   curl https://api.ipify.org
   
   # 3. Go to https://developer.clashofclans.com/
   # 4. Create new API key with this IP
   # 5. Update application.properties
   ```

3. **Update API Key:**
   ```properties
   clash.api.key=YOUR_NEW_API_KEY_HERE
   ```

---

### 2. 🏠 ISP Static IP
**Best for: Production**

#### Steps:
1. Contact your ISP
2. Request static IP address (may cost $5-20/month)
3. Update API key with new static IP
4. Configure router if needed

---

### 3. ☁️ Cloud Deployment
**Best for: Production & Scaling**

#### AWS Example:
```bash
# 1. Create EC2 instance
# 2. Allocate Elastic IP
# 3. Associate with instance
# 4. Deploy application
# 5. Update API key with Elastic IP
```

#### DigitalOcean Example:
```bash
# 1. Create droplet
# 2. Note the static IP
# 3. Deploy application
# 4. Update API key
```

---

### 4. 🔄 Multiple API Keys (Quick Fix)
**Best for: Immediate development**

#### Setup:
1. **Create API keys for common IPs:**
   - Home IP
   - Office IP  
   - Mobile hotspot IP
   - VPN IP

2. **Use environment-specific configs:**
   ```properties
   # application-home.properties
   clash.api.key=home-ip-api-key
   
   # application-office.properties  
   clash.api.key=office-ip-api-key
   
   # application-vpn.properties
   clash.api.key=vpn-ip-api-key
   ```

3. **Run with specific profile:**
   ```bash
   # At home
   java -jar app.jar --spring.profiles.active=home
   
   # At office
   java -jar app.jar --spring.profiles.active=office
   
   # With VPN
   java -jar app.jar --spring.profiles.active=vpn
   ```

---

## 🛠️ Automated Tools

### IP Monitor Script
Run the provided script to monitor IP changes:

```bash
# Windows
scripts/check-ip.bat

# Linux/Mac  
python3 scripts/update-clash-api-key.py
```

### Current IP Check
```bash
# Get current IP
curl https://api.ipify.org

# Check if it matches your API key restriction
```

---

## 🚀 Immediate Action Plan

### Option A: VPN Solution (Recommended)
1. **Get NordVPN or PureVPN** with dedicated IP
2. **Connect to VPN**
3. **Check IP:** `curl https://api.ipify.org`
4. **Create new API key** at https://developer.clashofclans.com/
5. **Update application.properties**
6. **Restart backend**

### Option B: Multiple Keys Solution  
1. **Check current IP:** `curl https://api.ipify.org`
2. **Create API key** for current IP
3. **Create API keys** for other common locations
4. **Update application.properties** with current key
5. **Test API call**

### Option C: Cloud Deployment
1. **Deploy to DigitalOcean/AWS**
2. **Note static IP**
3. **Create API key** for cloud IP
4. **Update configuration**
5. **Test remotely**

---

## 🔍 Testing Your Solution

After implementing any solution:

```bash
# Test API endpoint
curl "http://localhost:8080/api/fetch-currentwar?clanTag=%232GC8P2L88"

# Should return either:
# - War data with clan names
# - NO_WAR response  
# - Proper error message (not empty array)
```

---

## 💡 Pro Tips

1. **Keep backup API keys** for different IPs
2. **Use environment variables** for API keys
3. **Monitor IP changes** with automated scripts  
4. **Document your IP addresses** and corresponding API keys
5. **Consider cloud deployment** for production

---

## 🆘 Troubleshooting

### Empty Array Response
- IP restriction violation
- Invalid API key
- Network connectivity issues

### API Error 403
- Wrong IP address in API key
- API key expired
- Rate limiting

### Connection Timeout
- Network issues
- Firewall blocking
- VPN connectivity problems

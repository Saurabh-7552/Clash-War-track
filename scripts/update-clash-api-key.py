#!/usr/bin/env python3
"""
Clash of Clans API Key Auto-Updater
Automatically creates new API key when IP address changes
"""

import requests
import json
import time
import os
from datetime import datetime

class ClashAPIKeyUpdater:
    def __init__(self):
        # You need to get these from Clash of Clans Developer Portal
        self.email = os.getenv('CLASH_DEV_EMAIL', 'your-email@example.com')
        self.password = os.getenv('CLASH_DEV_PASSWORD', 'your-password')
        self.api_name = "Auto-Updated-Key"
        self.api_description = "Auto-updated API key for dynamic IP"
        
    def get_current_ip(self):
        """Get current public IP address"""
        try:
            response = requests.get('https://api.ipify.org?format=json', timeout=10)
            return response.json()['ip']
        except Exception as e:
            print(f"Error getting IP: {e}")
            return None
    
    def create_new_api_key(self, ip_address):
        """Create new API key for current IP"""
        # Note: This requires reverse engineering the Clash of Clans developer portal
        # which may violate their terms of service
        print(f"Would create new API key for IP: {ip_address}")
        print("⚠️  Manual step required: Update API key in developer portal")
        return None
    
    def update_application_config(self, new_api_key):
        """Update application.properties with new API key"""
        config_path = "../src/main/resources/application.properties"
        if os.path.exists(config_path):
            # Read current config
            with open(config_path, 'r') as f:
                lines = f.readlines()
            
            # Update API key line
            with open(config_path, 'w') as f:
                for line in lines:
                    if line.startswith('clash.api.key='):
                        f.write(f'clash.api.key={new_api_key}\n')
                    else:
                        f.write(line)
            
            print(f"✅ Updated application.properties with new API key")
        else:
            print(f"❌ Config file not found: {config_path}")
    
    def check_and_update(self):
        """Check current IP and update if needed"""
        current_ip = self.get_current_ip()
        if not current_ip:
            return False
        
        print(f"🌐 Current IP: {current_ip}")
        
        # Store last known IP
        ip_file = "last_known_ip.txt"
        last_ip = None
        
        if os.path.exists(ip_file):
            with open(ip_file, 'r') as f:
                last_ip = f.read().strip()
        
        if current_ip != last_ip:
            print(f"🔄 IP changed from {last_ip} to {current_ip}")
            
            # Save new IP
            with open(ip_file, 'w') as f:
                f.write(current_ip)
            
            print("📝 Manual Action Required:")
            print(f"   1. Go to https://developer.clashofclans.com/")
            print(f"   2. Create new API key for IP: {current_ip}")
            print(f"   3. Update your application.properties file")
            print(f"   4. Restart your Spring Boot application")
            
            return True
        else:
            print("✅ IP unchanged, no action needed")
            return False

def main():
    updater = ClashAPIKeyUpdater()
    
    print("🚀 Clash of Clans API Key IP Monitor")
    print("=" * 50)
    
    while True:
        try:
            updater.check_and_update()
            print(f"💤 Sleeping for 5 minutes... (Press Ctrl+C to stop)")
            time.sleep(300)  # Check every 5 minutes
        except KeyboardInterrupt:
            print("\n👋 Stopping IP monitor...")
            break
        except Exception as e:
            print(f"❌ Error: {e}")
            time.sleep(60)  # Wait 1 minute on error

if __name__ == "__main__":
    main()

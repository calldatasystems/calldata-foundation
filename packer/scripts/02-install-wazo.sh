#!/bin/bash
set -ex

echo "=== Installing Wazo Platform using official E-UC Stack installer ==="

# Use the official Wazo installation script for Debian 12
# This is the recommended installation method from wazo.io
echo "Running official Wazo E-UC Stack installer..."
apt-get update
apt-get install -y sudo wget curl

# Download and run the official installer script
wget -O /tmp/wazo-install.sh http://mirror.wazo.io/fai/wazo-install-scripts/wazo-install.sh
chmod +x /tmp/wazo-install.sh
bash /tmp/wazo-install.sh

# Wait for services to fully start
echo "Waiting for services to initialize..."
sleep 120

# Install wazo-ui if not already installed
echo "Installing wazo-ui..."
apt-get install -y wazo-ui || true

# Verify services are running
echo "Checking service status..."
for svc in postgresql asterisk nginx wazo-auth; do
    systemctl status $svc --no-pager || true
done

echo "=== Wazo Platform Installation Complete ==="

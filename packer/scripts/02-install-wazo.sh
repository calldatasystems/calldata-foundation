#!/bin/bash
set -e

echo "=== Installing Wazo Platform ==="

# Add Wazo repository
wget -O - https://mirror.wazo.community/wazo-platform.gpg | gpg --dearmor -o /usr/share/keyrings/wazo-platform.gpg
echo "deb [signed-by=/usr/share/keyrings/wazo-platform.gpg] https://mirror.wazo.community/debian wazo-dev-bookworm main" > /etc/apt/sources.list.d/wazo-platform.list

apt-get update

# Install Wazo platform (all-in-one)
apt-get install -y wazo-platform

# Wait for services to initialize
sleep 30

# Install wazo-ui
apt-get install -y wazo-ui

# Ensure all services are enabled
systemctl enable postgresql@15-main
systemctl enable asterisk
systemctl enable nginx
systemctl enable wazo-auth
systemctl enable wazo-confd
systemctl enable wazo-calld
systemctl enable wazo-dird
systemctl enable wazo-agentd
systemctl enable wazo-amid
systemctl enable wazo-call-logd
systemctl enable wazo-chatd
systemctl enable wazo-phoned
systemctl enable wazo-plugind
systemctl enable wazo-provd
systemctl enable wazo-webhookd
systemctl enable wazo-websocketd
systemctl enable wazo-ui

echo "=== Wazo Platform Installed ==="

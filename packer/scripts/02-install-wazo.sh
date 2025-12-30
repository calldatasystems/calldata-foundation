#!/bin/bash
set -ex

echo "=== Installing Wazo Platform ==="

# Add Wazo repository key
echo "Adding Wazo repository..."
mkdir -p /usr/share/keyrings
wget -q -O - https://mirror.wazo.community/wazo_current.key | gpg --dearmor > /usr/share/keyrings/wazo-keyring.gpg

# Add Wazo repository (using pelican-bookworm for Debian 12)
echo "deb [signed-by=/usr/share/keyrings/wazo-keyring.gpg] http://mirror.wazo.community/debian/pelican-bookworm pelican-bookworm main" > /etc/apt/sources.list.d/wazo.list

echo "Updating package lists..."
apt-get update

# Install Wazo platform
echo "Installing wazo-platform (this will take 10-15 minutes)..."
apt-get install -y wazo-platform

# Wait for services to initialize
echo "Waiting for services to initialize..."
sleep 60

# Install wazo-ui
echo "Installing wazo-ui..."
apt-get install -y wazo-ui

# Enable key services (using || true to avoid failures if service doesn't exist)
echo "Enabling services..."
for svc in postgresql asterisk nginx wazo-auth wazo-confd wazo-calld wazo-dird wazo-agentd wazo-amid wazo-call-logd wazo-chatd wazo-phoned wazo-plugind wazo-provd wazo-webhookd wazo-websocketd wazo-ui; do
    systemctl enable $svc 2>/dev/null || true
done

echo "=== Wazo Platform Installed ==="

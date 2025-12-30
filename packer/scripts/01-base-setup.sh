#!/bin/bash
set -e

echo "=== Base Setup ==="

# Disable automatic updates
echo 'APT::Periodic::Update-Package-Lists "0";' > /etc/apt/apt.conf.d/20auto-upgrades
echo 'APT::Periodic::Unattended-Upgrade "0";' >> /etc/apt/apt.conf.d/20auto-upgrades

systemctl stop unattended-upgrades.service || true
systemctl disable unattended-upgrades.service || true
systemctl mask unattended-upgrades.service || true

# Wait for any apt locks
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    echo "Waiting for apt lock..."
    sleep 5
done

# Update system
apt-get update
apt-get upgrade -y

# Install SSM agent
cd /tmp
curl -o amazon-ssm-agent.deb https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
dpkg -i amazon-ssm-agent.deb || true
systemctl enable amazon-ssm-agent

# Install basic dependencies
apt-get install -y \
    curl \
    wget \
    gnupg \
    ca-certificates \
    apt-transport-https \
    python3 \
    python3-pip \
    git \
    jq

echo "=== Base Setup Complete ==="

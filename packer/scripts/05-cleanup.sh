#!/bin/bash
set -e

echo "=== Cleanup for AMI ==="

# Clean apt cache
apt-get clean
apt-get autoremove -y
rm -rf /var/lib/apt/lists/*

# Clean temp files
rm -rf /tmp/*
rm -rf /var/tmp/*

# Clean logs
find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;
find /var/log -type f -name "*.gz" -delete

# Remove SSH host keys (regenerated on first boot)
rm -f /etc/ssh/ssh_host_*

# Remove machine-id (regenerated on first boot)
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id

# Clear cloud-init state
cloud-init clean --logs || true

# Remove bash history
rm -f /root/.bash_history
rm -f /home/*/.bash_history

# Remove packer temp files
rm -rf /tmp/calldata-foundation

# Sync filesystem
sync

echo "=== Cleanup Complete ==="
echo "AMI is ready for imaging"

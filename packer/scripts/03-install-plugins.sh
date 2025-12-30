#!/bin/bash
set -e

echo "=== Installing IVR Plugin ==="

# Clone the repository
cd /tmp
rm -rf calldata-foundation
git clone https://github.com/calldatasystems/calldata-foundation.git

# Install IVR system plugin
cd calldata-foundation/plugins/ivr-system
chmod +x install.sh
./install.sh || true

# Verify installation
if command -v wazo-ivr &> /dev/null; then
    echo "IVR CLI tool installed successfully"
else
    echo "Warning: IVR CLI tool not found"
fi

# Check if service is running
if systemctl is-active --quiet wazo-ivr-api; then
    echo "IVR API service running"
else
    echo "Warning: IVR API service not running (will start on boot)"
fi

echo "=== IVR Plugin Installed ==="

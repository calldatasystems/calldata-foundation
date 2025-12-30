#!/bin/bash
set -e

echo "=== Configuring Wazo Platform ==="

# Wait for services to be ready
sleep 60

# Run setup wizard via API
echo "Running Wazo setup wizard..."
curl -k -X POST https://localhost/api/setupd/1.0/setup \
    -H "Content-Type: application/json" \
    -d '{
        "engine_language": "en_US",
        "engine_password": "'"${WAZO_ROOT_PASSWORD}"'",
        "engine_internal_address": "127.0.0.1",
        "engine_license": true
    }' || echo "Setup wizard may have already run"

# Wait for setup to complete
sleep 30

# Create root admin user if not exists
echo "Creating admin user..."
wazo-auth-cli user list | grep -q " root " || \
    wazo-auth-cli user create root --password "${WAZO_ROOT_PASSWORD}" --purpose external_api --enable

# Get root user UUID and assign admin policy
ROOT_UUID=$(wazo-auth-cli user list | grep " root " | awk '{print $2}')
if [ ! -z "$ROOT_UUID" ]; then
    wazo-auth-cli user add --policy wazo_default_admin_policy "$ROOT_UUID" 2>/dev/null || echo "Policy may already be assigned"
    echo "Admin user configured: root"
fi

# Create firstboot script for instance-specific config
cat > /usr/local/bin/wazo-firstboot << 'FIRSTBOOT'
#!/bin/bash
# This script runs on first boot to do instance-specific configuration

# Get instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id || echo "unknown")
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "")

echo "Wazo firstboot: Instance $INSTANCE_ID, IP: $PUBLIC_IP"

# Pull secrets from AWS Secrets Manager (if configured)
# aws secretsmanager get-secret-value --secret-id wazo/config --query SecretString --output text

# Mark firstboot complete
touch /var/lib/wazo/.firstboot-complete
FIRSTBOOT

chmod +x /usr/local/bin/wazo-firstboot

# Create systemd service for firstboot
cat > /etc/systemd/system/wazo-firstboot.service << 'SERVICE'
[Unit]
Description=Wazo First Boot Configuration
After=network-online.target wazo-auth.service
Wants=network-online.target
ConditionPathExists=!/var/lib/wazo/.firstboot-complete

[Service]
Type=oneshot
ExecStart=/usr/local/bin/wazo-firstboot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable wazo-firstboot

echo "=== Wazo Configuration Complete ==="

#!/bin/bash
set -ex

echo "=== Configuring Wazo Platform ==="

# Wait for services to be fully ready after E-UC Stack installation
echo "Waiting for services to stabilize..."
sleep 120

# Verify key services are running
echo "Verifying services..."
for svc in postgresql asterisk nginx; do
    systemctl is-active $svc && echo "$svc is running" || echo "$svc not running (may be normal)"
done

# The E-UC Stack installer handles the setup wizard
# We just need to create the admin user for API access

# Try to create admin user (may fail if already exists or not yet ready)
echo "Attempting to create admin user..."
wazo-auth-cli user create root --password "${WAZO_ROOT_PASSWORD:-P@ssw0rd}" --purpose external_api --enable 2>/dev/null || echo "Admin user may already exist"

# Try to assign admin policy
echo "Attempting to assign admin policy..."
ROOT_UUID=$(wazo-auth-cli user list 2>/dev/null | grep -w "root" | awk '{print $2}' || true)
if [ ! -z "$ROOT_UUID" ]; then
    wazo-auth-cli user add --policy wazo_default_admin_policy "$ROOT_UUID" 2>/dev/null || echo "Policy assignment failed or already assigned"
    echo "Admin user UUID: $ROOT_UUID"
else
    echo "Could not find root user - will need to create manually after boot"
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

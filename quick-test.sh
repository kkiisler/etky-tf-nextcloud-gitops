#!/bin/bash

# Quick test script for Nextcloud deployment

echo "=== Quick Nextcloud Deployment Test ==="
echo ""

# Get server IP
SERVER_IP=$(terraform output -raw nextcloud_vm_public_ip 2>/dev/null)
echo "Server IP: $SERVER_IP"
echo ""

# Test key components
echo "1. Testing HTTPS access..."
if curl -k -s -o /dev/null -w "%{http_code}" https://$SERVER_IP | grep -q "200\|302\|303"; then
    echo "✓ HTTPS is working"
else
    echo "✗ HTTPS is not working"
fi

echo ""
echo "2. Getting admin password..."
ADMIN_PASS=$(terraform output -raw nextcloud_admin_password)
echo "Admin password: $ADMIN_PASS"

echo ""
echo "3. Testing login page..."
if curl -k -s https://$SERVER_IP/index.php/login | grep -q "requesttoken"; then
    echo "✓ Login page is accessible"
else
    echo "✗ Login page is not accessible"
fi

echo ""
echo "=== Next Steps ==="
echo "1. Point your domain (etky.amanda.tools) to: $SERVER_IP"
echo "2. Access: https://etky.amanda.tools"
echo "3. Login with: admin / $ADMIN_PASS"
echo ""
echo "To check containers on server:"
echo "ssh kkiisler@$SERVER_IP 'cd ~/nextcloud && docker-compose ps'"
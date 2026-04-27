#!/bin/bash
#
# Set Hostname Helper Script
# Change the container hostname after deployment
#

set -e

clear
echo "========================================"
echo "  Change Container Hostname"
echo "========================================"
echo ""

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "⚠️  This script requires root privileges"
    echo ""
    read -p "Run with sudo? [Y/n]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        sudo "$0" "$@"
        exit $?
    else
        echo "❌ Cancelled"
        exit 1
    fi
fi

echo "Current hostname: $(hostname)"
echo ""
echo "⚠️  Changing the hostname will:"
echo "   - Update /etc/hostname"
echo "   - Update /etc/hosts"
echo "   - Require container restart to fully apply"
echo ""

# Get new hostname
read -p "Enter new hostname: " NEW_HOSTNAME

# Validate hostname
if [[ ! $NEW_HOSTNAME =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$ ]]; then
    echo ""
    echo "❌ Invalid hostname!"
    echo "   Hostname must:"
    echo "   - Start and end with alphanumeric characters"
    echo "   - Only contain letters, numbers, and hyphens"
    echo "   - Not start or end with a hyphen"
    exit 1
fi

echo ""
read -p "Set hostname to '$NEW_HOSTNAME'? [Y/n]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
    echo "❌ Cancelled"
    exit 0
fi

# Set hostname
echo ""
echo "🔧 Setting hostname..."

# Update /etc/hostname
echo "$NEW_HOSTNAME" > /etc/hostname

# Update /etc/hosts
sed -i "s/^127.0.1.1.*/127.0.1.1\t$NEW_HOSTNAME/" /etc/hosts || \
    echo "127.0.1.1	$NEW_HOSTNAME" >> /etc/hosts

# Apply immediately (won't survive restart without docker-compose change)
hostname "$NEW_HOSTNAME"

echo ""
echo "========================================"
echo "✅ Hostname Updated!"
echo "========================================"
echo ""
echo "Current hostname: $(hostname)"
echo ""
echo "⚠️  IMPORTANT: To make this permanent:"
echo ""
echo "1. Update your docker-compose.yml or Portainer environment variable:"
echo "   HOSTNAME=$NEW_HOSTNAME"
echo ""
echo "2. Redeploy the container in Portainer:"
echo "   Stacks → docker-dev → Pull and redeploy"
echo ""
echo "OR restart the container:"
echo "   docker restart $(hostname)"
echo ""
echo "💡 Until you update the configuration and redeploy,"
echo "   the hostname will revert on container restart."
echo ""

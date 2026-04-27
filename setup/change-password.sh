#!/bin/bash
#
# Change User Password Helper Script
# This script helps you change your container user password
#

set -e

clear
echo "========================================"
echo "  Change Password"
echo "========================================"
echo ""
echo "This script will help you change your password."
echo ""
echo "⚠️  IMPORTANT: You are about to change the password for user: $(whoami)"
echo ""

# Check if running as root (shouldn't be)
if [ "$(id -u)" -eq 0 ]; then
    echo "❌ Error: Don't run this script as root!"
    echo "   Run as your regular user (the one whose password you want to change)"
    exit 1
fi

# Confirm
read -p "Continue? [Y/n]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
    echo "❌ Cancelled"
    exit 0
fi

echo ""
echo "🔐 Changing password for user: $(whoami)"
echo ""
echo "You will be prompted for:"
echo "  1. Your current password"
echo "  2. Your new password (twice for confirmation)"
echo ""

# Change password using passwd command
if passwd; then
    echo ""
    echo "========================================"
    echo "✅ Password changed successfully!"
    echo "========================================"
    echo ""
    echo "Your password for user '$(whoami)' has been updated."
    echo ""
    echo "💡 Tips:"
    echo "  - Use your new password for SSH login"
    echo "  - Consider setting up SSH keys for password-less access"
    echo "  - Run: ./generate-ssh-keys.sh"
    echo ""
else
    echo ""
    echo "========================================"
    echo "❌ Password change failed"
    echo "========================================"
    echo ""
    echo "Possible reasons:"
    echo "  - Current password was incorrect"
    echo "  - New password doesn't meet complexity requirements"
    echo "  - New passwords didn't match"
    echo ""
    echo "Please try again."
    exit 1
fi

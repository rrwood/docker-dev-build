#!/bin/bash
#
# Ngrok Installation Script
# Usage: install-ngrok [auth_token]
#

set -e

echo "Installing ngrok..."

# Download and install ngrok
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
tar xvzf ngrok-v3-stable-linux-amd64.tgz
sudo mv ngrok /usr/local/bin/
rm ngrok-v3-stable-linux-amd64.tgz
chmod +x /usr/local/bin/ngrok

echo "Ngrok installed successfully!"

# Configure auth token if provided
if [ -n "$1" ]; then
    echo "Configuring ngrok with auth token..."
    ngrok config add-authtoken "$1"
    echo "Auth token configured!"
else
    echo ""
    echo "To configure ngrok, run:"
    echo "  ngrok config add-authtoken YOUR_AUTH_TOKEN"
fi

echo ""
echo "Ngrok is ready to use!"
echo "Example: ngrok http 8080"

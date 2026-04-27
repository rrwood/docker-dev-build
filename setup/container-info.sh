#!/bin/bash
#
# Container Information Display
# Shows current container configuration
#

echo "========================================"
echo "  Container Information"
echo "========================================"
echo ""
echo "👤 User Information:"
echo "   Username:     $(whoami)"
echo "   User ID:      $(id -u)"
echo "   Group ID:     $(id -g)"
echo "   Home Dir:     $HOME"
echo "   Shell:        $SHELL"
echo ""
echo "🖥️  System Information:"
echo "   Hostname:     $(hostname)"
echo "   OS:           $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "   Kernel:       $(uname -r)"
echo ""
echo "🌐 Network Information:"
echo "   IP Addresses:"
ip -4 addr show | grep inet | awk '{print "      " $2}' | grep -v "127.0.0.1"
echo ""
echo "🔧 Installed Tools:"
for tool in claude litellm ngrok python3 git curl; do
    if command -v $tool &> /dev/null; then
        VERSION=$(which $tool 2>/dev/null)
        echo "   ✓ $tool: $VERSION"
    else
        echo "   ✗ $tool: not installed"
    fi
done
echo ""
echo "📁 Disk Usage:"
df -h /app /home 2>/dev/null | awk 'NR==1 || /\/app/ || /\/home/' | sed 's/^/   /'
echo ""
echo "💾 Memory Usage:"
free -h | sed 's/^/   /'
echo ""
echo "🔑 SSH Keys:"
if [ -f ~/.ssh/id_rsa.pub ]; then
    echo "   ✓ SSH key exists"
    echo "   Public key: ~/.ssh/id_rsa.pub"
else
    echo "   ✗ No SSH key found"
    echo "   Generate one with: cd ~/setup && ./generate-ssh-keys.sh"
fi
echo ""
if [ -f ~/.ssh/authorized_keys ]; then
    KEY_COUNT=$(grep -c "^ssh-" ~/.ssh/authorized_keys 2>/dev/null || echo 0)
    echo "   Authorized keys: $KEY_COUNT"
else
    echo "   No authorized_keys file"
fi
echo ""
echo "📖 For more information, see: ~/setup/README.md"
echo ""

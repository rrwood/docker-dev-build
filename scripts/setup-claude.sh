#!/bin/bash
#
# Claude CLI Installation Script
# Usage: setup-claude
#

set -e

echo "======================================"
echo "Claude CLI Installation"
echo "======================================"
echo ""

# Check if Claude is already installed
if command -v claude &> /dev/null; then
    echo "Claude CLI is already installed!"
    echo "Version: $(claude --version 2>&1 || echo 'unknown')"
    echo ""
    read -p "Reinstall? [y/N]: " reinstall
    if [[ ! "$reinstall" =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 0
    fi
fi

echo "Installing Claude CLI..."
curl -fsSL https://claude.ai/install.sh | sh

echo ""
echo "======================================"
echo "✓ Claude CLI installed successfully!"
echo "======================================"
echo ""
echo "To get started:"
echo "  1. Run 'claude' to launch Claude Code"
echo "  2. Or run 'setup-litellm' to use Claude Code with Gemini (free)"
echo ""

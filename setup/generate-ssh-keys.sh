#!/bin/bash
#
# SSH Key Generation Helper Script
# Generates SSH keys and helps configure password-less access
#

set -e

clear
echo "========================================"
echo "  SSH Key Generator"
echo "========================================"
echo ""

# Key location
KEY_DIR="$HOME/.ssh"
KEY_FILE="$KEY_DIR/id_rsa"
PUB_KEY_FILE="$KEY_FILE.pub"

# Check if key already exists
if [ -f "$KEY_FILE" ]; then
    echo "⚠️  SSH key already exists at: $KEY_FILE"
    echo ""
    ls -lh "$KEY_FILE" "$PUB_KEY_FILE" 2>/dev/null || echo "(Public key not found)"
    echo ""
    read -p "Generate a new key pair (will backup existing)? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "Using existing key. Your public key is:"
        echo "========================================"
        cat "$PUB_KEY_FILE"
        echo "========================================"
        echo ""
        echo "💡 Copy this key to your client machines for password-less access."
        echo "   See ~/setup/README.md for instructions."
        exit 0
    fi

    # Backup existing keys
    echo ""
    echo "📦 Backing up existing keys..."
    BACKUP_DIR="$KEY_DIR/backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    mv "$KEY_FILE" "$BACKUP_DIR/" 2>/dev/null || true
    mv "$PUB_KEY_FILE" "$BACKUP_DIR/" 2>/dev/null || true
    echo "✓ Backed up to: $BACKUP_DIR"
fi

# Create .ssh directory if it doesn't exist
mkdir -p "$KEY_DIR"
chmod 700 "$KEY_DIR"

echo ""
echo "🔑 Generating new SSH key pair..."
echo ""

# Generate key
ssh-keygen -t rsa -b 4096 -f "$KEY_FILE" -N "" -C "$(whoami)@$(hostname)"

# Set proper permissions
chmod 600 "$KEY_FILE"
chmod 644 "$PUB_KEY_FILE"

echo ""
echo "========================================"
echo "✅ SSH Key Generated Successfully!"
echo "========================================"
echo ""
echo "📁 Key location: $KEY_FILE"
echo "📁 Public key:   $PUB_KEY_FILE"
echo ""

# Show public key
echo "📋 Your PUBLIC key (copy this to client machines):"
echo "========================================"
cat "$PUB_KEY_FILE"
echo "========================================"
echo ""

# Option to add to authorized_keys
read -p "Add this key to authorized_keys (allow this key to access this container)? [Y/n]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
    AUTHORIZED_KEYS="$KEY_DIR/authorized_keys"

    # Create authorized_keys if doesn't exist
    touch "$AUTHORIZED_KEYS"
    chmod 600 "$AUTHORIZED_KEYS"

    # Check if key already in authorized_keys
    if grep -qF "$(cat $PUB_KEY_FILE)" "$AUTHORIZED_KEYS" 2>/dev/null; then
        echo "✓ Key already in authorized_keys"
    else
        cat "$PUB_KEY_FILE" >> "$AUTHORIZED_KEYS"
        echo "✓ Key added to authorized_keys"
    fi
    echo ""
fi

# Instructions
echo "========================================"
echo "📖 Next Steps"
echo "========================================"
echo ""
echo "To use this key from a client machine:"
echo ""
echo "Option 1: Copy the public key manually"
echo "  1. Copy the public key shown above"
echo "  2. On your client machine, add it to ~/.ssh/authorized_keys"
echo ""
echo "Option 2: Transfer the private key to your client"
echo "  1. On this container, display the private key:"
echo "     cat $KEY_FILE"
echo "  2. Copy the entire key (including BEGIN/END lines)"
echo "  3. On your client machine, save to ~/.ssh/id_rsa_container"
echo "  4. Set permissions: chmod 600 ~/.ssh/id_rsa_container"
echo "  5. SSH: ssh -i ~/.ssh/id_rsa_container $(whoami)@YOUR_CONTAINER_IP"
echo ""
echo "Option 3: Use ssh-copy-id (from your client)"
echo "  ssh-copy-id $(whoami)@YOUR_CONTAINER_IP"
echo ""
echo "💡 See ~/setup/README.md for detailed instructions"
echo ""

# Show current authorized keys
if [ -f "$KEY_DIR/authorized_keys" ]; then
    KEY_COUNT=$(grep -c "^ssh-" "$KEY_DIR/authorized_keys" 2>/dev/null || echo 0)
    echo "📊 Current authorized_keys has $KEY_COUNT key(s)"
fi

echo ""
echo "✅ Setup complete!"

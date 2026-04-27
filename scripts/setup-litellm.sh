#!/bin/bash
#
# LiteLLM Setup Script for Claude Code + Gemini Integration
# This script sets up litellm as a proxy to use Gemini with Claude Code
#
# Usage: setup-litellm
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/litellm"
CONFIG_FILE="$CONFIG_DIR/litellm_config.yaml"
ENV_FILE="$CONFIG_DIR/.env"
ENV_EXAMPLE="$CONFIG_DIR/.env.example"

echo "======================================"
echo "LiteLLM Setup for Claude Code + Gemini"
echo "======================================"
echo ""

# Install litellm with proxy support
echo "[1/4] Installing litellm..."
pip3 install --upgrade 'litellm[proxy]'
echo "✓ LiteLLM installed successfully"
echo ""

# Create config directory
echo "[2/4] Creating configuration directory..."
mkdir -p "$CONFIG_DIR"
echo "✓ Config directory created at $CONFIG_DIR"
echo ""

# Create litellm config file
echo "[3/4] Creating LiteLLM configuration..."
cat > "$CONFIG_FILE" << 'EOF'
model_list:
  - model_name: gemini-2.5-flash
    litellm_params:
      model: gemini/gemini-2.5-flash
      api_key: os.environ/GOOGLE_API_KEY

  - model_name: gemini-2.0-flash-exp
    litellm_params:
      model: gemini/gemini-2.0-flash-exp
      api_key: os.environ/GOOGLE_API_KEY

# Optional: Add other Gemini models
#  - model_name: gemini-pro
#    litellm_params:
#      model: gemini/gemini-pro
#      api_key: os.environ/GOOGLE_API_KEY

general_settings:
  master_key: DUMMY_KEY
EOF

echo "✓ Config file created at $CONFIG_FILE"
echo ""

# Create .env.example file
echo "[4/4] Creating environment configuration..."
cat > "$ENV_EXAMPLE" << 'EOF'
# Google AI Studio API Key
# Get yours at: https://aistudio.google.com/app/apikey
GOOGLE_API_KEY=your_google_api_key_here

# Claude Code Environment Variables
# These tell Claude Code to use the LiteLLM proxy
ANTHROPIC_BASE_URL=http://localhost:4000
ANTHROPIC_API_KEY=DUMMY_KEY
ANTHROPIC_AUTH_TOKEN=DUMMY_KEY
ANTHROPIC_MODEL=gemini-2.5-flash
EOF

echo "✓ Example environment file created at $ENV_EXAMPLE"
echo ""

# Check if .env already exists
if [ ! -f "$ENV_FILE" ]; then
    cp "$ENV_EXAMPLE" "$ENV_FILE"
    echo "======================================"
    echo "⚠️  IMPORTANT: Configure your API key"
    echo "======================================"
    echo ""
    echo "Edit the following file and add your Google API key:"
    echo "  $ENV_FILE"
    echo ""
    echo "Get your API key from: https://aistudio.google.com/app/apikey"
    echo ""
else
    echo "⚠️  Existing .env file found, not overwriting"
    echo "   Location: $ENV_FILE"
    echo ""
fi

# Create helper scripts
echo "Creating helper scripts..."

# Start script
cat > "$CONFIG_DIR/start-litellm.sh" << 'EOF'
#!/bin/bash
CONFIG_DIR="$HOME/.config/litellm"
source "$CONFIG_DIR/.env"
litellm --config "$CONFIG_DIR/litellm_config.yaml" --port 4000
EOF
chmod +x "$CONFIG_DIR/start-litellm.sh"

# Export environment script
cat > "$CONFIG_DIR/export-claude-env.sh" << 'EOF'
#!/bin/bash
CONFIG_DIR="$HOME/.config/litellm"
if [ -f "$CONFIG_DIR/.env" ]; then
    export ANTHROPIC_BASE_URL=http://localhost:4000
    export ANTHROPIC_API_KEY=DUMMY_KEY
    export ANTHROPIC_AUTH_TOKEN=DUMMY_KEY
    export ANTHROPIC_MODEL=gemini-2.5-flash
    echo "✓ Claude Code environment variables exported"
    echo "  Model: $ANTHROPIC_MODEL"
    echo "  Proxy: $ANTHROPIC_BASE_URL"
else
    echo "⚠️  Error: .env file not found at $CONFIG_DIR/.env"
    exit 1
fi
EOF
chmod +x "$CONFIG_DIR/export-claude-env.sh"

echo "✓ Helper scripts created"
echo ""

echo "======================================"
echo "✓ Setup Complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo ""
echo "1. Add your Google API key to:"
echo "   $ENV_FILE"
echo ""
echo "2. Start the LiteLLM proxy:"
echo "   $CONFIG_DIR/start-litellm.sh"
echo ""
echo "3. In another terminal, export Claude environment variables:"
echo "   source $CONFIG_DIR/export-claude-env.sh"
echo ""
echo "4. Run Claude Code:"
echo "   claude"
echo ""
echo "Optional: Add to your ~/.bashrc or ~/.zshrc:"
echo "   alias start-litellm='$CONFIG_DIR/start-litellm.sh'"
echo "   alias claude-env='source $CONFIG_DIR/export-claude-env.sh'"
echo ""
echo "For systemd service setup, see:"
echo "   $CONFIG_DIR/README.md"

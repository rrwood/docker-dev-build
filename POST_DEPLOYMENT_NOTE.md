# Post-Deployment Setup

After your container is deployed and running, you can install optional components.

## Install Claude CLI

Claude CLI is **not installed during build** to avoid build failures. Install it after deployment:

```bash
# SSH into the container
ssh devuser@192.168.111.15

# Run the setup script
setup-claude
```

The `setup-claude` script will:
- Check if Claude is already installed
- Download and install Claude CLI
- Make it available globally

## Install ngrok (if not installed during build)

```bash
# SSH into the container
ssh devuser@192.168.111.15

# Install ngrok with auth token
install-ngrok YOUR_AUTH_TOKEN

# Or without auth token
install-ngrok
```

## Setup LiteLLM (Claude Code + Gemini Integration)

Use free Gemini models with Claude Code:

```bash
# SSH into the container
ssh devuser@192.168.111.15

# Run the setup script
setup-litellm

# Edit config and add your Google API key
nano ~/.config/litellm/.env
# Get API key from: https://aistudio.google.com/app/apikey

# Start the LiteLLM proxy (in one terminal)
~/.config/litellm/start-litellm.sh

# In another terminal, export environment variables
source ~/.config/litellm/export-claude-env.sh

# Run Claude Code
claude
```

## Why isn't Claude CLI installed during build?

The Claude CLI installation script can fail in Docker build contexts, which would prevent the entire container from building. By making it a post-deployment step:

1. ✅ Container builds reliably every time
2. ✅ You can choose when to install Claude
3. ✅ Build failures don't block container deployment
4. ✅ Easier to troubleshoot if installation fails

The `setup-claude` script is already included in the container and ready to use.

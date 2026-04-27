# Helper Scripts

This directory contains helper scripts for the development container.

## Available Scripts

### install-ngrok

Installs ngrok for exposing local services to the internet.

**Usage:**
```bash
# Basic installation
install-ngrok

# Install with auth token
install-ngrok YOUR_AUTH_TOKEN
```

**What it does:**
- Downloads and installs ngrok binary
- Optionally configures auth token
- Makes ngrok available globally

**Example usage after installation:**
```bash
# Expose a local web server
ngrok http 8080

# Expose SSH
ngrok tcp 22
```

### setup-litellm

Sets up LiteLLM as a proxy to use Google Gemini models with Claude Code (free alternative to Anthropic API).

**Usage:**
```bash
setup-litellm
```

**What it does:**
1. Installs `litellm[proxy]` via pip
2. Creates `~/.config/litellm/` directory structure
3. Generates configuration file (`litellm_config.yaml`)
4. Creates environment file template (`.env`)
5. Creates helper scripts:
   - `start-litellm.sh` - Start the LiteLLM proxy server
   - `export-claude-env.sh` - Export environment variables for Claude Code

**Post-installation steps:**

1. **Add your Google API key:**
   ```bash
   nano ~/.config/litellm/.env
   # Add your API key from https://aistudio.google.com/app/apikey
   ```

2. **Start the LiteLLM proxy:**
   ```bash
   ~/.config/litellm/start-litellm.sh
   ```

3. **In another terminal, set up Claude Code environment:**
   ```bash
   source ~/.config/litellm/export-claude-env.sh
   claude
   ```

**Configuration files created:**
- `~/.config/litellm/litellm_config.yaml` - Model configuration
- `~/.config/litellm/.env` - API keys and settings
- `~/.config/litellm/.env.example` - Template file
- `~/.config/litellm/start-litellm.sh` - Start script
- `~/.config/litellm/export-claude-env.sh` - Environment setup script

## How LiteLLM Works

LiteLLM acts as a translation layer between Claude Code and Gemini:

```
Claude Code → LiteLLM Proxy (port 4000) → Google Gemini API
(Anthropic format)     ↓                    (Gemini format)
                   Translation
```

- **Claude Code** sends requests in Anthropic's format to `http://localhost:4000`
- **LiteLLM** translates these to Gemini's format and forwards them
- **Google Gemini** processes the request and returns results
- **LiteLLM** translates the response back to Anthropic's format

This allows you to use Claude Code for free with Google's AI Studio API instead of paying for Anthropic's API.

## Troubleshooting

### LiteLLM won't start

```bash
# Check if Python and pip are installed
python3 --version
pip3 --version

# Reinstall litellm
pip3 install --upgrade 'litellm[proxy]'

# Check if port 4000 is already in use
netstat -tuln | grep 4000
```

### Claude Code can't connect to LiteLLM

```bash
# Verify environment variables
echo $ANTHROPIC_BASE_URL  # Should be http://localhost:4000
echo $ANTHROPIC_MODEL     # Should be gemini-2.5-flash

# Test LiteLLM proxy directly
curl http://localhost:4000/health

# Re-export variables
source ~/.config/litellm/export-claude-env.sh
```

### API authentication errors

1. Check your Google API key in `~/.config/litellm/.env`
2. Verify key at https://aistudio.google.com/app/apikey
3. Ensure the key has proper permissions
4. Check rate limits (free tier: 15 requests/minute, 1500 requests/day)

## References

- [LiteLLM Documentation](https://docs.litellm.ai/)
- [Gemini API Documentation](https://ai.google.dev/gemini-api/docs)
- [ngrok Documentation](https://ngrok.com/docs)

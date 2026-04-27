# Development Server Docker Container

A containerized development environment with Claude CLI, SSH access, and support for Claude Code + Gemini integration via LiteLLM.

## 📖 Documentation

- **👉 [START_HERE.md](START_HERE.md)** - **NEW USER? START HERE!** 🌟
- **[SETUP_OPTIONS.md](SETUP_OPTIONS.md)** - Compare all setup methods 🔀
- **[PORTAINER_QUICK_START.md](PORTAINER_QUICK_START.md)** - Deploy to Portainer in 5 minutes 🐳
- **[QUICKSTART.md](QUICKSTART.md)** - Auto-deploy in 5 minutes ⚡
- **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)** - Project layout and file reference 📁
- **[scripts/README.md](scripts/README.md)** - Helper scripts documentation 🛠️

## Features

- **Alpine Linux** base image for minimal footprint
- **Claude CLI** optional installation
- **SSH Server** with user-only access (root login disabled)
- **Password and Key-based authentication** supported
- **Automated setup** with interactive configuration script
- **Optional ngrok** installation via helper script
- **LiteLLM integration** for using Gemini with Claude Code (free alternative to Anthropic API)

## Quick Start (Automated Setup)

**The easiest way to get started is using the interactive setup script:**

### Linux/Mac/WSL:
```bash
./setup.sh
```

### Windows - Option 1 (Pure PowerShell - No dependencies):
```batch
setup-powershell.bat
```
or run directly:
```powershell
.\setup.ps1
```

### Windows - Option 2 (Git Bash or WSL):
```batch
setup.bat
```

The setup script will:
- ✅ Prompt for username and password
- ✅ Ask if you want Claude CLI and/or ngrok pre-installed
- ✅ Optionally generate SSH keys and configure SSH config
- ✅ Generate Dockerfile and docker-compose.yml
- ✅ (Bash version only) Build and start the container automatically

**PowerShell version** generates files for manual Portainer deployment.
**Bash version** can also build and start automatically.

**That's it! Follow the prompts and you'll be up and running in minutes.**

## Manual Setup (Advanced)

If you prefer manual configuration:

### 1. Build the Container

```bash
docker-compose build
```

### 2. Start the Container

```bash
docker-compose up -d
```

### 3. Access the Container

**Default credentials (if you didn't run setup.sh):**
- Username: `devuser`
- Password: (set in Dockerfile)
- SSH Port: `22`

```bash
# SSH into the container
ssh devuser@192.168.111.15  # Or your configured IP

# Or use docker exec
docker exec -it docker-dev su - devuser
```

### 4. Change Default Password

```bash
# Inside the container
passwd
```

### 5. (Optional) Add SSH Key

```bash
# On your host machine
ssh-copy-id devuser@192.168.111.15

# Or manually
cat ~/.ssh/id_rsa.pub | ssh devuser@192.168.111.15 "cat >> ~/.ssh/authorized_keys"
```

## What the Setup Script Does

The `setup.sh` script provides an interactive way to configure your container:

1. **Prompts for configuration:**
   - Container username and password
   - Container hostname and IP address
   - Optional: Auto-install Claude CLI
   - Optional: Auto-install ngrok (with auth token)

2. **SSH key management (if accessing from setup machine):**
   - Generates an SSH key pair (`~/.ssh/docker-dev-container`)
   - Updates `~/.ssh/config` with connection details
   - Copies public key to container's authorized_keys

3. **Generates custom Dockerfile:**
   - Based on your selections
   - Includes only requested components

4. **Updates docker-compose.yml:**
   - Sets hostname and IP address
   - Preserves network configuration

5. **Builds and starts container:**
   - Optional automatic build
   - Copies SSH keys if configured
   - Tests SSH connection

**Example Setup Session:**
```bash
$ ./setup.sh

======================================
Docker Development Container Setup
======================================

Enter username for container user [devuser]: myuser
Enter password for myuser: ****
Confirm password: ****
Enter container hostname [docker-dev]: dev-server
Enter container IP address [192.168.111.15]: 192.168.111.50

Install Claude CLI automatically? [Y/n]: y
Install ngrok automatically? [y/N]: n

Will you access this container from THIS machine? [Y/n]: y
SSH key will be created at: /home/user/.ssh/docker-dev-container

[Configuration summary displayed]

Proceed with this configuration? [Y/n]: y

✓ Dockerfile generated successfully
✓ docker-compose.yml updated
✓ SSH key generated
✓ Container built successfully
✓ Container started
✓ SSH keys copied
✓ SSH connection verified!

Container is running and ready to use!
```

## Optional Tools

### Install ngrok

If you need ngrok for exposing local services:

```bash
# Inside the container
install-ngrok

# With auth token
install-ngrok YOUR_AUTH_TOKEN
```

### Setup LiteLLM (Claude Code + Gemini Integration)

Use Gemini models for free with Claude Code (no Anthropic subscription required):

```bash
# Inside the container
setup-litellm
```

This will:
1. Install LiteLLM with proxy support
2. Create configuration files in `~/.config/litellm/`
3. Generate example environment file
4. Create helper scripts for starting the proxy

**After running setup-litellm:**

1. Edit `~/.config/litellm/.env` and add your Google API key:
   ```bash
   nano ~/.config/litellm/.env
   ```
   Get your API key from: https://aistudio.google.com/app/apikey

2. Start the LiteLLM proxy:
   ```bash
   ~/.config/litellm/start-litellm.sh
   ```

3. In another terminal, export Claude environment variables:
   ```bash
   source ~/.config/litellm/export-claude-env.sh
   ```

4. Run Claude Code:
   ```bash
   claude
   ```

**Available Gemini Models:**
- `gemini-2.5-flash` (default, fastest)
- `gemini-2.0-flash-exp` (experimental)
- `gemini-pro` (can be enabled in config)

**Optional: Create systemd service for LiteLLM**

To run LiteLLM automatically on container start, create a systemd service (Alpine uses OpenRC, so adapt as needed):

```bash
# For systems with systemd, create:
# /etc/systemd/system/litellm.service

[Unit]
Description=LiteLLM Proxy for Claude Code
After=network.target

[Service]
Type=simple
User=devuser
WorkingDirectory=/home/devuser
EnvironmentFile=/home/devuser/.config/litellm/.env
ExecStart=/usr/bin/litellm --config /home/devuser/.config/litellm/litellm_config.yaml --port 4000
Restart=always

[Install]
WantedBy=multi-user.target
```

## Security Notes

1. **Change default password immediately** after first login
2. **Root SSH login is disabled** for security
3. `devuser` has sudo access without password (change in Dockerfile if needed)
4. Store API keys in `.env` files and **never commit them to git**
5. Add `.env` to `.gitignore`

## Customization

### Add More Users

```bash
# Inside container
sudo adduser newuser
sudo passwd newuser
sudo mkdir -p /home/newuser/.ssh
sudo chmod 700 /home/newuser/.ssh
sudo chown newuser:newuser /home/newuser/.ssh

# Optional: Add to sudoers
echo 'newuser ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/newuser
```

### Modify SSH Configuration

Edit `/etc/ssh/sshd_config` and restart SSH:

```bash
sudo nano /etc/ssh/sshd_config
sudo rc-service sshd restart
```

### Available Gemini Models in LiteLLM

Edit `~/.config/litellm/litellm_config.yaml` to add or modify models:

```yaml
model_list:
  - model_name: gemini-2.5-flash
    litellm_params:
      model: gemini/gemini-2.5-flash
      api_key: os.environ/GOOGLE_API_KEY

  - model_name: gemini-pro
    litellm_params:
      model: gemini/gemini-pro
      api_key: os.environ/GOOGLE_API_KEY
```

See all available models: https://docs.litellm.ai/docs/providers/gemini

## Troubleshooting

### SSH Connection Issues

```bash
# Check SSH service status
docker exec -it adobe-dev rc-service sshd status

# Restart SSH service
docker exec -it adobe-dev rc-service sshd restart

# Check logs
docker logs adobe-dev
```

### LiteLLM Proxy Issues

```bash
# Check if proxy is running
curl http://localhost:4000/health

# View proxy logs
# (check terminal where start-litellm.sh is running)

# Test with curl
curl -X POST http://localhost:4000/v1/messages \
  -H "Content-Type: application/json" \
  -H "x-api-key: DUMMY_KEY" \
  -d '{
    "model": "gemini-2.5-flash",
    "max_tokens": 100,
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

### Claude Code Not Connecting

1. Verify environment variables are set:
   ```bash
   echo $ANTHROPIC_BASE_URL
   echo $ANTHROPIC_MODEL
   ```

2. Ensure LiteLLM proxy is running on port 4000

3. Check Google API key is valid in `~/.config/litellm/.env`

4. Try exporting variables again:
   ```bash
   source ~/.config/litellm/export-claude-env.sh
   ```

## Network Configuration

The docker-compose.yml uses macvlan networking. Adjust settings for your network:

```yaml
networks:
  adobe-macvlan:
    driver: macvlan
    driver_opts:
      parent: eth0  # Change to your network interface
    ipam:
      config:
        - subnet: 192.168.111.0/24      # Your subnet
          gateway: 192.168.111.1         # Your gateway
          ip_range: 192.168.111.200/29   # Container IP range
```

## References

- [Claude Code Documentation](https://claude.ai/docs)
- [LiteLLM Documentation](https://docs.litellm.ai/)
- [Gemini API Documentation](https://ai.google.dev/gemini-api/docs)
- [Setup Guide: Claude Code + Gemini (Medium)](https://prince-arora-aws.medium.com/how-i-set-up-claude-code-for-free-no-subscription-no-credit-card-and-what-i-learned-along-the-2cba880682a2)
- [Troubleshooting: Claude Code + Gemini (Medium)](https://prince-arora-aws.medium.com/my-claude-code-gemini-setup-broke-heres-what-was-actually-happening-de00e84a29cf)

## License

This configuration is provided as-is for development purposes.

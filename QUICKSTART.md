# Quick Start Guide

Get your development container running in 5 minutes!

## Prerequisites

- Docker and Docker Compose installed
- Git Bash (Windows) or Bash shell (Linux/Mac)
- Network access to pull Docker images

## Step 1: Run Setup Script

### Linux/Mac/WSL:
```bash
cd /path/to/devserverdocker
./setup.sh
```

### Windows (PowerShell/CMD):
```batch
cd C:\path\to\devserverdocker
setup.bat
```

## Step 2: Follow the Prompts

The script will ask you:

1. **Username and Password**
   - Choose a username for the container (default: `devuser`)
   - Set a secure password

2. **Container Details**
   - Hostname (default: `docker-dev`)
   - IP address (default: `192.168.111.15`)

3. **Optional Components**
   - Install Claude CLI? (recommended: **Yes**)
   - Install ngrok? (only if needed)

4. **SSH Setup**
   - Will you access from this machine? (recommended: **Yes**)
   - Automatically sets up SSH keys and config

5. **Build Container?**
   - Build and start now? (recommended: **Yes**)

## Step 3: Connect to Container

If you selected SSH setup, simply run:

```bash
ssh <container-hostname>

# Example:
ssh docker-dev
```

Or connect manually:

```bash
ssh <username>@<ip-address>

# Example:
ssh myuser@192.168.111.50
```

## Step 4: Setup LiteLLM (Optional - for Free Claude Code)

Once inside the container:

```bash
# 1. Setup LiteLLM
setup-litellm

# 2. Edit the .env file and add your Google API key
nano ~/.config/litellm/.env
# Get your key from: https://aistudio.google.com/app/apikey

# 3. Start the LiteLLM proxy (in one terminal)
~/.config/litellm/start-litellm.sh

# 4. In another terminal, export environment variables
source ~/.config/litellm/export-claude-env.sh

# 5. Run Claude Code
claude
```

## Common Commands

### Container Management
```bash
# Start container
docker-compose up -d

# Stop container
docker-compose down

# Rebuild container
docker-compose build

# View logs
docker logs docker-dev

# Access container shell
docker exec -it docker-dev su - devuser
```

### Inside Container
```bash
# Install ngrok (if not done during setup)
install-ngrok

# Install Claude CLI (if not done during setup)
setup-claude

# Setup Claude Code + Gemini
setup-litellm

# Change password
passwd

# Check SSH keys
ls -la ~/.ssh/
```

## SSH Connection Info

After setup, your SSH config (`~/.ssh/config`) will have:

```
Host <container-hostname>
    HostName <ip-address>
    User <username>
    IdentityFile ~/.ssh/docker-dev-container
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

This allows you to simply run:
```bash
ssh <container-hostname>
```

## Troubleshooting

### Can't connect via SSH

1. Check container is running:
   ```bash
   docker ps | grep docker-dev
   ```

2. Test network connectivity:
   ```bash
   ping <container-ip>
   ```

3. Try password authentication:
   ```bash
   ssh -o PreferredAuthentications=password <username>@<ip-address>
   ```

4. Check SSH service in container:
   ```bash
   docker exec docker-dev rc-service sshd status
   ```

### Container won't start

1. Check Docker logs:
   ```bash
   docker logs docker-dev
   ```

2. Verify network configuration:
   ```bash
   docker network ls
   ```

3. Try rebuilding:
   ```bash
   docker-compose down
   docker-compose build --no-cache
   docker-compose up -d
   ```

### LiteLLM not connecting

1. Verify proxy is running:
   ```bash
   curl http://localhost:4000/health
   ```

2. Check environment variables:
   ```bash
   env | grep ANTHROPIC
   ```

3. Verify Google API key:
   ```bash
   cat ~/.config/litellm/.env
   ```

## Next Steps

- Read the full [README.md](README.md) for advanced configuration
- Check [scripts/README.md](scripts/README.md) for helper script documentation
- Set up your development environment inside the container
- Configure Claude Code with Gemini for free AI assistance

## Need Help?

- Full documentation: [README.md](README.md)
- Script documentation: [scripts/README.md](scripts/README.md)
- LiteLLM docs: https://docs.litellm.ai/
- Claude Code docs: https://claude.ai/docs

---

**Happy coding! 🚀**

# Development Server Docker Container

A containerized development environment with Claude CLI, SSH access, and support for Claude Code + Gemini integration via LiteLLM.

## 🚀 Quick Deploy with Portainer

**The easiest way to deploy this container is using Portainer.**

See **[PORTAINER_DEPLOY.md](PORTAINER_DEPLOY.md)** for complete Portainer deployment instructions.

### Quick Steps:

1. **Create stack in Portainer**
2. **Point to GitHub repository**: `https://github.com/rrwood/docker-dev-build`
3. **Configure environment variables** (username, password, IP address)
4. **Deploy** - Portainer automatically pulls setup scripts from GitHub and builds

## Features

- **Alpine Linux** base image for minimal footprint
- **Claude CLI** - optional installation during build
- **SSH Server** with user-only access (root login disabled)
- **Password and Key-based authentication** supported
- **Automated setup** - scripts pulled from GitHub during Docker build
- **LiteLLM integration** for using Gemini with Claude Code (free alternative to Anthropic API)
- **Optional ngrok** installation during build or post-deployment
- **Portainer-optimized** - designed for easy Portainer stack deployment

## Documentation

### 📖 Getting Started
- **[QUICKSTART.md](QUICKSTART.md)** - Quick deployment guide ⚡
- **[PORTAINER_DEPLOY.md](PORTAINER_DEPLOY.md)** - Complete Portainer deployment guide 🐳
- **[DEPLOY_CHECKLIST.md](DEPLOY_CHECKLIST.md)** - Step-by-step deployment checklist ✅
- **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** - Overview and quick reference 📋

### 🔐 SSH & Security
- **[SSH_SETUP_GUIDE.md](SSH_SETUP_GUIDE.md)** - Complete SSH key setup (Windows/Linux/Mac) 🔑

### 🔧 Troubleshooting
- **[PORTAINER_HOSTNAME_RESERVED.md](PORTAINER_HOSTNAME_RESERVED.md)** - Why HOSTNAME doesn't work ⚠️
- **[PORTAINER_CACHE_PURGE.md](PORTAINER_CACHE_PURGE.md)** - Clear Docker caches 🧹
- **[TROUBLESHOOTING_PORTAINER.md](TROUBLESHOOTING_PORTAINER.md)** - General Portainer issues 🔍

### 🛠️ Scripts & Tools
- **[scripts/README.md](scripts/README.md)** - Build-time helper scripts
- **[setup/README.md](setup/README.md)** - Post-deployment setup scripts (in container)

## Manual Deployment (Alternative)

If you prefer not to use Portainer:

### 1. Clone Repository

```bash
git clone https://github.com/rrwood/docker-dev-build.git
cd docker-dev-build
```

### 2. Configure Environment

```bash
cp .env.example .env
nano .env  # Edit with your settings
```

### 3. Create Macvlan Network (if not exists)

```bash
docker network create -d macvlan \
  --subnet=192.168.111.0/24 \
  --gateway=192.168.111.1 \
  --ip-range=192.168.111.200/29 \
  -o parent=eth0 \
  dev-macvlan
```

### 4. Build and Deploy

```bash
docker-compose up -d
```

### 5. Access Container

```bash
ssh devuser@192.168.111.15
# Or: docker exec -it docker-dev su - devuser
```

### 6. First Login Setup (IMPORTANT!)

On first login, change your password and setup SSH keys:

```bash
# Change default password
cd ~/setup
./change-password.sh

# Generate SSH keys
./generate-ssh-keys.sh

# View complete setup guide
cat ~/setup/README.md
```

## Configuration

All configuration is done via environment variables in `.env` file:

```env
# Container Settings
USERNAME=devuser                    # Container user
USER_PASSWORD=changeme123          # User password
CONTAINER_NAME=docker-dev          # Container name
HOSTNAME=docker-dev                # Hostname
CONTAINER_IP=192.168.111.15       # IP address

# Optional Components
INSTALL_NGROK=false              # Install ngrok during build
NGROK_AUTH_TOKEN=                # ngrok auth token

# Workspace
WORKSPACE_PATH=./workspace       # Host path for /app volume
TIMEZONE=UTC                     # Container timezone
```

## Available Helper Scripts

Scripts are automatically installed from GitHub during build to `~/setup/`:

### setup-litellm.sh
Setup LiteLLM proxy for Claude Code + Gemini integration (free alternative to Anthropic API)

```bash
~/setup/setup-litellm.sh
```

### install-ngrok.sh
Install ngrok for exposing local services (if not installed during build)

```bash
~/setup/install-ngrok.sh [AUTH_TOKEN]
```

### setup-claude.sh
Install Claude CLI (if not installed during build)

```bash
~/setup/setup-claude.sh
```

See **[scripts/README.md](scripts/README.md)** for detailed documentation.

## LiteLLM Setup (Claude Code + Gemini)

Use Gemini models for free with Claude Code:

```bash
# 1. Inside container, run setup
~/setup/setup-litellm.sh

# 2. Add your Google API key
nano ~/.config/litellm/.env
# Get key from: https://aistudio.google.com/app/apikey

# 3. Start LiteLLM proxy
~/.config/litellm/start-litellm.sh

# 4. In another terminal, export environment variables
source ~/.config/litellm/export-claude-env.sh

# 5. Run Claude Code
claude
```

## How It Works

### Build Process

When Portainer (or docker-compose) builds the container:

1. **Dockerfile clones this GitHub repository** during build
2. **Setup scripts are copied** from `scripts/` directory
3. **Optional components installed** based on build arguments (Claude CLI, ngrok)
4. **Scripts available** in `/usr/local/bin/` for use
5. **Repository is cleaned up** after scripts are copied

### No Manual Setup Required

Unlike traditional approaches, you don't need to:
- Run setup scripts on your host machine
- Manually copy files into the container
- Keep scripts in sync

Everything is **pulled fresh from GitHub** during each build.

## Customization

### Use Different GitHub Branch

Set in `.env`:
```env
GITHUB_BRANCH=develop
```

### Use Forked Repository

Set in `.env`:
```env
GITHUB_REPO=https://github.com/YOUR_USERNAME/docker-dev-build.git
```

### Modify Scripts

1. Fork the repository
2. Modify scripts in `scripts/` directory
3. Point `GITHUB_REPO` to your fork
4. Rebuild container

## Security Notes

1. **Change default password** - Set strong password in `USER_PASSWORD`
2. **Root SSH login disabled** for security
3. User has sudo access without password (change in Dockerfile if needed)
4. **Store API keys in `.env`** and never commit them
5. `.env` is in `.gitignore`

## Network Configuration

The docker-compose.yml uses **macvlan networking** for direct network access.

Adjust for your network:
- `CONTAINER_IP` - IP address for container
- Network settings in `docker network create` command

## Troubleshooting

### SSH Connection Issues

```bash
# Check SSH service
docker exec -it docker-dev rc-service sshd status

# Restart SSH
docker exec -it docker-dev rc-service sshd restart

# View logs
docker logs docker-dev
```

### Build Issues

```bash
# Check build logs
docker-compose build --no-cache

# In Portainer: Stacks → docker-dev → Build logs
```

### LiteLLM Issues

```bash
# Check proxy health
curl http://localhost:4000/health

# Verify environment variables
echo $ANTHROPIC_BASE_URL
echo $ANTHROPIC_MODEL

# Re-export
source ~/.config/litellm/export-claude-env.sh
```

## References

- [Claude Code Documentation](https://claude.ai/docs)
- [LiteLLM Documentation](https://docs.litellm.ai/)
- [Gemini API Documentation](https://ai.google.dev/gemini-api/docs)
- [Portainer Documentation](https://docs.portainer.io/)
- [Docker Macvlan Networks](https://docs.docker.com/network/macvlan/)

## License

This configuration is provided as-is for development purposes.

# Quick Start Guide

## Deploy with Portainer (Recommended)

### Prerequisites
- Portainer installed and running
- Macvlan network named `dev-macvlan` (see below if you need to create it)

### Steps

1. **In Portainer, create a new Stack**
   - Go to **Stacks** → **Add stack**
   - Name: `docker-dev`

2. **Choose Git Repository**
   - Repository URL: `https://github.com/rrwood/docker-dev-build`
   - Reference: `refs/heads/main`
   - Compose path: `docker-compose.yml`

3. **Add Environment Variables**
   
   Click **Add environment variable** for each:
   
   ```env
   USERNAME=devuser
   USER_PASSWORD=YOUR_SECURE_PASSWORD
   CONTAINER_NAME=docker-dev
   HOSTNAME=docker-dev
   CONTAINER_IP=192.168.111.15
   INSTALL_NGROK=false
   WORKSPACE_PATH=./workspace
   TIMEZONE=UTC
   ```

4. **Deploy the stack**
   
   Click **Deploy the stack** - Portainer will:
   - Clone the GitHub repository
   - Pull setup scripts during build
   - Build the container
   - Start the container

5. **Access your container**
   
   ```bash
   ssh devuser@192.168.111.15
   # Use the password you set in USER_PASSWORD
   ```

6. **First login - Run setup scripts** (IMPORTANT!)
   
   ```bash
   # Change your default password
   cd ~/setup
   ./change-password.sh
   
   # Generate SSH keys
   ./generate-ssh-keys.sh
   
   # View all setup options
   cat ~/setup/README.md
   ```

**That's it!** Your container is ready to use.

---

## Create Macvlan Network (If Needed)

If the `dev-macvlan` network doesn't exist:

```bash
docker network create -d macvlan \
  --subnet=192.168.111.0/24 \
  --gateway=192.168.111.1 \
  --ip-range=192.168.111.200/29 \
  -o parent=eth0 \
  dev-macvlan
```

**Adjust for your network:**
- `--subnet` - Your network subnet
- `--gateway` - Your network gateway
- `--ip-range` - Range for container IPs
- `-o parent` - Your network interface (eth0, ens18, etc.)

---

## Manual Deployment (Alternative)

If not using Portainer:

```bash
# 1. Clone repository
git clone https://github.com/rrwood/docker-dev-build.git
cd docker-dev-build

# 2. Configure
cp .env.example .env
nano .env  # Edit settings

# 3. Deploy
docker-compose up -d

# 4. Access
ssh devuser@192.168.111.15
```

---

## Post-Deployment Setup

### Setup LiteLLM (Claude Code + Gemini)

Use free Gemini models with Claude Code:

```bash
# Inside container
setup-litellm

# Add Google API key
nano ~/.config/litellm/.env

# Start proxy
~/.config/litellm/start-litellm.sh

# In another terminal
source ~/.config/litellm/export-claude-env.sh
claude
```

Get your Google API key: https://aistudio.google.com/app/apikey

### Install ngrok (if not installed during build)

```bash
install-ngrok YOUR_AUTH_TOKEN
```

---

## Common Commands

### Container Management
```bash
# View logs
docker logs docker-dev

# Access container shell
docker exec -it docker-dev su - devuser

# Restart container
docker restart docker-dev
```

### Inside Container
```bash
# Setup Claude Code + Gemini
setup-litellm

# Install ngrok (if not done during build)
install-ngrok

# Install Claude CLI (if not done during build)
setup-claude

# Change password
passwd
```

---

## Troubleshooting

### Can't connect via SSH

```bash
# Check container is running
docker ps | grep docker-dev

# Test network connectivity
ping 192.168.111.15

# Check SSH service
docker exec docker-dev rc-service sshd status

# Restart SSH service
docker exec docker-dev rc-service sshd restart
```

### Container won't start

```bash
# View logs
docker logs docker-dev

# Verify network exists
docker network ls | grep dev-macvlan

# In Portainer: Stacks → docker-dev → Build logs
```

### LiteLLM not connecting

```bash
# Check proxy health
curl http://localhost:4000/health

# Check environment variables
env | grep ANTHROPIC

# Verify Google API key
cat ~/.config/litellm/.env
```

---

## Key Features

✅ **No manual setup scripts** - Everything pulled from GitHub during build  
✅ **Portainer-optimized** - Deploy as a stack with Git integration  
✅ **Automatic updates** - Pull and redeploy to get latest changes  
✅ **Customizable** - Configure via environment variables  
✅ **Helper scripts included** - setup-litellm, install-ngrok, setup-claude  

---

## Need More Info?

- **[PORTAINER_DEPLOY.md](PORTAINER_DEPLOY.md)** - Full Portainer deployment guide
- **[README.md](README.md)** - Complete documentation
- **[scripts/README.md](scripts/README.md)** - Helper scripts reference

---

**Happy coding! 🚀**

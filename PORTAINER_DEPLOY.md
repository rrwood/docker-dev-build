# Portainer Deployment Guide

This guide shows how to deploy the development container using Portainer.

## Prerequisites

1. **Portainer installed and running**
2. **Macvlan network created** (named `dev-macvlan`)
   
   If you need to create the network:
   ```bash
   docker network create -d macvlan \
     --subnet=192.168.111.0/24 \
     --gateway=192.168.111.1 \
     --ip-range=192.168.111.200/29 \
     -o parent=eth0 \
     dev-macvlan
   ```

## Method 1: Deploy via Portainer Stacks (Recommended)

### Step 1: Create Stack

1. In Portainer, go to **Stacks** → **Add stack**
2. Name your stack (e.g., `docker-dev`)
3. Choose **Git Repository** as build method

### Step 2: Configure Git Repository

- **Repository URL**: `https://github.com/rrwood/docker-dev-build`
- **Repository reference**: `refs/heads/main`
- **Compose path**: `docker-compose.yml`

### Step 3: Configure Environment Variables

Click **Add environment variable** and configure:

```env
# Required Settings
USERNAME=devuser
USER_PASSWORD=YOUR_SECURE_PASSWORD_HERE
CONTAINER_NAME=docker-dev
HOSTNAME=docker-dev
CONTAINER_IP=192.168.111.15

# Workspace & Timezone
WORKSPACE_PATH=./workspace
TIMEZONE=America/New_York

# Optional Components (ngrok only - Claude installed via setup-claude script post-deployment)
INSTALL_NGROK=false
NGROK_AUTH_TOKEN=

# Repository Settings (usually don't change)
GITHUB_REPO=https://github.com/rrwood/docker-dev-build.git
GITHUB_BRANCH=main
```

### Step 4: Deploy

Click **Deploy the stack**

Portainer will:
1. Clone the repository
2. Pull setup scripts from GitHub during build
3. Build the container with your configuration
4. Start the container

## Method 2: Deploy via Portainer Web Editor

### Step 1: Create Stack

1. Go to **Stacks** → **Add stack**
2. Name your stack: `docker-dev`
3. Choose **Web editor**

### Step 2: Paste Configuration

Paste the contents of `docker-compose.yml` into the editor.

### Step 3: Configure Environment Variables

Add the environment variables as shown in Method 1, Step 3.

### Step 4: Deploy

Click **Deploy the stack**

## Method 3: Manual Container Creation

1. Go to **Containers** → **Add container**
2. Configure manually (not recommended, use Stacks instead)

## Post-Deployment

### Access the Container

**Via SSH:**
```bash
ssh devuser@192.168.111.15
# Password: (whatever you set in USER_PASSWORD)
```

**Via Portainer Console:**
1. Go to **Containers** → `docker-dev`
2. Click **Console**
3. Connect as user `devuser`
4. Execute: `su - devuser`

### 🔐 Important First Steps

After logging in for the first time, you'll see a welcome message with setup instructions.

**1. Change Your Default Password (IMPORTANT!):**
```bash
cd ~/setup
./change-password.sh
```

**2. Generate SSH Keys (Recommended):**
```bash
cd ~/setup
./generate-ssh-keys.sh
```

**3. View Setup Guide:**
```bash
cat ~/setup/README.md
```

### Available Setup Scripts

All setup scripts are located in `~/setup/`:

- `change-password.sh` - Change your user password
- `generate-ssh-keys.sh` - Generate SSH keys for password-less access
- `container-info.sh` - Display container information
- `README.md` - Complete setup guide

### Setup LiteLLM (Optional - for Claude Code + Gemini)

```bash
# Inside container
setup-litellm

# Follow prompts to configure Google API key
nano ~/.config/litellm/.env

# Start LiteLLM proxy
~/.config/litellm/start-litellm.sh

# In another terminal, export environment variables
source ~/.config/litellm/export-claude-env.sh
```

### Install ngrok (if not installed during build)

```bash
# Inside container
install-ngrok YOUR_AUTH_TOKEN
```

### Change Password

```bash
# Inside container
passwd
```

## Updating the Container

### Update from Git Repository

If you deployed via Git Repository (Method 1):

1. Go to **Stacks** → `docker-dev`
2. Click **Pull and redeploy**
3. Portainer will pull latest changes from GitHub and rebuild

### Manual Update

If you deployed via Web Editor (Method 2):

1. Stop and remove the stack
2. Create new stack with updated configuration
3. Deploy

## Customization

### Change Container IP

Modify `CONTAINER_IP` environment variable to use a different IP in your network.

### Use Different GitHub Branch

Set `GITHUB_BRANCH=develop` (or any branch) to pull scripts from a different branch.

### Use Forked Repository

1. Fork the repository to your GitHub account
2. Set `GITHUB_REPO=https://github.com/YOUR_USERNAME/docker-dev-build.git`

## Troubleshooting

### Container won't start

1. Check Portainer logs: **Containers** → `docker-dev` → **Logs**
2. Verify macvlan network exists: **Networks**
3. Verify IP address is not in use

### Can't connect via SSH

```bash
# Check if SSH is running
docker exec -it docker-dev rc-service sshd status

# Restart SSH
docker exec -it docker-dev rc-service sshd restart
```

### Build fails

1. Check **Stacks** → `docker-dev` → **Build logs**
2. Verify GitHub repository is accessible
3. Check network connectivity from Portainer host

## Network Configuration

If using a different network setup:

1. **Create network** (if not exists):
   ```bash
   docker network create -d macvlan \
     --subnet=YOUR_SUBNET \
     --gateway=YOUR_GATEWAY \
     --ip-range=YOUR_IP_RANGE \
     -o parent=YOUR_INTERFACE \
     dev-macvlan
   ```

2. **Update environment variables** to match your network

## Security Notes

1. **Always change the default password** (`USER_PASSWORD`)
2. **Use strong passwords** for production deployments
3. **Restrict SSH access** if exposed to internet
4. **Keep API keys secure** - never commit `.env` files with secrets

## References

- [Portainer Documentation](https://docs.portainer.io/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Macvlan Network Guide](https://docs.docker.com/network/macvlan/)

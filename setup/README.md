# Welcome to Your Development Container! 🚀

This directory contains setup scripts to help you configure your container after deployment.

## 🔐 Important First Steps

### 1. Change Your Default Password

**Your container was deployed with a default password.** Change it immediately:

```bash
./change-password.sh
```

This script will:
- Prompt for your current password
- Ask for a new secure password
- Confirm the password change
- Update your user password

### 2. Setup SSH Keys (Recommended)

For secure, password-less SSH access:

```bash
./generate-ssh-keys.sh
```

This script will:
- Generate an SSH key pair (if one doesn't exist)
- Display your public key
- Optionally add the key to authorized_keys
- Show instructions for copying to your client machines

## 📋 Available Setup Scripts

| Script | Purpose |
|--------|---------|
| `change-password.sh` | Change your user password |
| `generate-ssh-keys.sh` | Generate SSH keys for password-less access |
| `setup-claude.sh` | Install Claude CLI |
| `setup-litellm.sh` | Setup LiteLLM for Claude Code + Gemini |
| `install-ngrok.sh` | Install ngrok (if not done during build) |

## 🛠️ Post-Deployment Setup Guide

### Step 1: Secure Your Container

```bash
# Change default password
./change-password.sh

# Generate SSH keys
./generate-ssh-keys.sh
```

### Step 2: Install Optional Tools

**Install Claude CLI:**
```bash
setup-claude
```

**Install ngrok (if needed):**
```bash
install-ngrok YOUR_AUTH_TOKEN
```

### Step 3: Setup Claude Code with Gemini (Free Alternative)

Use Google's Gemini models for free instead of paying for Anthropic API:

```bash
# 1. Setup LiteLLM
setup-litellm

# 2. Get your Google API key from: https://aistudio.google.com/app/apikey

# 3. Add your API key to the config
nano ~/.config/litellm/.env

# 4. Start the LiteLLM proxy (in one terminal)
~/.config/litellm/start-litellm.sh

# 5. In another terminal, export environment variables
source ~/.config/litellm/export-claude-env.sh

# 6. Run Claude Code
claude
```

## 📚 Container Information

Your container details:

- **Username:** Run `whoami` to see your username
- **Hostname:** Run `hostname` to see your hostname
- **IP Address:** Check your network configuration or Portainer settings
- **SSH Access:** `ssh username@container-ip`

## 🔑 SSH Key Setup Guide

After running `./generate-ssh-keys.sh`:

### On Your Client Machine (Windows - PowerShell)

```powershell
# Copy the public key shown by the script, then:
ssh username@container-ip "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
# Paste the public key when prompted, then press Ctrl+D

# Or if you already have the key in a file:
type C:\path\to\key.pub | ssh username@container-ip "cat >> ~/.ssh/authorized_keys"
```

### On Your Client Machine (Linux/Mac)

```bash
# Copy the public key shown by the script, then:
ssh username@container-ip "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
# Paste the public key when prompted, then press Ctrl+D

# Or use ssh-copy-id:
ssh-copy-id -i ~/.ssh/id_rsa.pub username@container-ip
```

### Configure SSH Client for Easy Access

Add to `~/.ssh/config` on your client machine:

```
Host docker-dev
    HostName container-ip
    User username
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

Then simply: `ssh docker-dev`

## 🆘 Troubleshooting

### Can't SSH into container

```bash
# Check SSH service status
sudo rc-service sshd status

# Restart SSH service
sudo rc-service sshd restart

# Check SSH config
sudo nano /etc/ssh/sshd_config
```

### Forgot password

If you've locked yourself out:

```bash
# From host machine, access container console:
docker exec -it container-name /bin/bash

# Then change password:
passwd username
```

### Permission issues

```bash
# Fix SSH directory permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chown -R $(whoami):$(whoami) ~/.ssh
```

## 📖 Additional Documentation

- **Main README:** `/home/$(whoami)/setup/CONTAINER_README.md`
- **Project Repository:** https://github.com/rrwood/docker-dev-build
- **Portainer Guide:** See PORTAINER_DEPLOY.md in repository

## 💡 Useful Commands

```bash
# Check container info
hostname
whoami
ip addr

# List installed tools
which claude
which litellm
which ngrok

# View available setup scripts
ls -la /usr/local/bin/ | grep setup

# Update package list
sudo apk update

# Install additional packages
sudo apk add package-name
```

## 🔄 Updating Your Container

To get the latest version of setup scripts:

1. In Portainer: Stacks → docker-dev → **Pull and redeploy**
2. This will rebuild the container with latest scripts from GitHub

**Note:** Your workspace data is preserved in the volume mount.

---

**Need help?** Check the repository documentation or open an issue on GitHub.

**Happy coding! 🚀**

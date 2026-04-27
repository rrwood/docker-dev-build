# Docker Development Container - Project Summary

## Overview

A production-ready, Portainer-optimized Docker container for development environments with:
- Alpine Linux base
- SSH access with key-based authentication
- Post-deployment setup scripts
- Optional Claude CLI, LiteLLM, and ngrok
- Automated deployment from GitHub

## ✅ Final Working Configuration

### Environment Variables (Use These Names!)

```env
USERNAME=your-username                  # Container user account
USER_PASSWORD=your-secure-password     # Initial password (change post-deployment)
CONTAINER_NAME=docker-dev              # Docker container name
CONTAINER_HOSTNAME=your-hostname       # ⚠️ Use CONTAINER_HOSTNAME not HOSTNAME!
CONTAINER_IP=192.168.111.15           # Static IP on macvlan network
WORKSPACE_PATH=./workspace             # Volume mount path
TIMEZONE=UTC                           # Container timezone
INSTALL_NGROK=false                    # Install ngrok during build (optional)
```

**Critical:** `HOSTNAME` is reserved by Docker/Portainer and will NOT work. Use `CONTAINER_HOSTNAME` instead.

## Deployment Methods

### Portainer (Recommended)

**Stacks → Add Stack:**
1. Build method: **Git Repository**
2. Repository URL: `https://github.com/rrwood/docker-dev-build`
3. Reference: `refs/heads/main`
4. Add environment variables manually (recommended over env file)
5. Deploy

**Why manual variables?** Env files must be in the repo. Since they contain passwords, they're gitignored and won't be available to Portainer.

### Manual Docker Compose

```bash
git clone https://github.com/rrwood/docker-dev-build.git
cd docker-dev-build
cp .env.example .env
nano .env  # Configure
docker-compose up -d
```

## Post-Deployment Setup

### 1. First Login

```bash
ssh username@container-ip
# You'll see a welcome message with setup instructions
```

### 2. Essential Security Steps

```bash
# Change default password
cd ~/setup
./change-password.sh

# Generate SSH keys for password-less access
./generate-ssh-keys.sh
```

### 3. Optional Tools

```bash
# Install Claude CLI
setup-claude

# Setup LiteLLM (use Gemini with Claude Code for free)
setup-litellm

# Install ngrok (if not done during build)
install-ngrok
```

## Helper Scripts Location

All scripts are in `~/setup/` directory:

| Script | Purpose |
|--------|---------|
| `change-password.sh` | Change user password |
| `generate-ssh-keys.sh` | Generate SSH keys |
| `container-info.sh` | Display system info |
| `verify-env.sh` | Verify environment variables |
| `set-hostname.sh` | Show hostname info (diagnostic) |

## Known Issues & Solutions

### Issue: Random Hostname (Container ID)

**Cause:** Used `HOSTNAME` instead of `CONTAINER_HOSTNAME` in environment variables.

**Solution:** `HOSTNAME` is reserved. Use `CONTAINER_HOSTNAME=your-hostname` instead.

### Issue: New Scripts Don't Appear After Redeploy

**Cause:** Docker build cache.

**Solution:**
```bash
# On Portainer host:
docker builder prune -a -f
# Then redeploy
```

### Issue: Env File Not Working in Portainer

**Cause:** Env files must be in the Git repository. Yours is gitignored (correct for security).

**Solution:** Set environment variables manually in Portainer UI instead of using env file path.

## Network Requirements

**Macvlan network named `dev-macvlan` must exist:**

```bash
docker network create -d macvlan \
  --subnet=192.168.111.0/24 \
  --gateway=192.168.111.1 \
  --ip-range=192.168.111.200/29 \
  -o parent=eth0 \
  dev-macvlan
```

Adjust subnet, gateway, and parent interface for your network.

## Documentation Index

### Getting Started
- **README.md** - Main documentation and features overview
- **QUICKSTART.md** - Fast deployment guide
- **PORTAINER_DEPLOY.md** - Complete Portainer deployment guide
- **DEPLOY_CHECKLIST.md** - Step-by-step deployment checklist

### SSH Setup
- **SSH_SETUP_GUIDE.md** - Complete SSH key setup (Windows, Linux, Mac)

### Troubleshooting
- **PORTAINER_CACHE_PURGE.md** - Clear Docker/Portainer caches
- **PORTAINER_HOSTNAME_RESERVED.md** - Why HOSTNAME doesn't work
- **PORTAINER_ENV_FILE.md** - Using env files with Portainer
- **TROUBLESHOOTING_PORTAINER.md** - General Portainer issues

### Technical Details
- **CHANGES.md** - Rebuild changelog and technical details
- **SETUP_FOLDER_INFO.md** - Developer info on setup scripts
- **POST_DEPLOYMENT_NOTE.md** - Post-deployment setup overview

### For Developers
- **push.sh / push.ps1** - Quick git push scripts (not in repo)
- **setup/** - Helper scripts installed in containers
- **scripts/** - Build-time scripts

## Architecture

```
GitHub Repository
    ↓
Portainer pulls from Git
    ↓
Builds Docker image
    ├─ Installs base packages
    ├─ Clones repo to get setup scripts
    ├─ Copies scripts to /usr/local/bin and ~/setup
    ├─ Creates user with credentials from env vars
    ├─ Sets hostname from CONTAINER_HOSTNAME
    └─ Starts SSH service
    ↓
Container runs
    ├─ User logs in via SSH
    ├─ Sees welcome message
    ├─ Runs ~/setup/ scripts
    └─ Installs optional tools as needed
```

## Files Not in Repository

These are gitignored (contain secrets or are user-specific):

- `*.home.env` - User environment files (passwords)
- `env.*` - Local env files
- `.env` - Standard env file
- `push.sh`, `push.ps1` - Local push scripts
- `*.key`, `*.pem` - SSH keys
- `.claude/` - Claude Code settings
- `workspace/` - Working directory data

## Quick Reference Commands

**Verify deployment:**
```bash
ssh username@container-ip
~/setup/verify-env.sh
```

**Check hostname:**
```bash
hostname  # Should show your CONTAINER_HOSTNAME value
```

**View container info:**
```bash
~/setup/container-info.sh
```

**Setup SSH keys from host:**
```bash
# Linux/Mac:
ssh-copy-id username@container-ip

# Windows PowerShell:
type ~\.ssh\id_rsa.pub | ssh username@container-ip "cat >> ~/.ssh/authorized_keys"
```

## Success Criteria

- [x] Container builds successfully from GitHub
- [x] Hostname is custom value (not container ID)
- [x] SSH access works
- [x] Setup scripts exist in ~/setup/
- [x] verify-env.sh shows correct values
- [x] Can install optional tools (Claude, LiteLLM, ngrok)
- [x] Password-less SSH works with keys
- [x] Container survives restarts with correct hostname

## Support

- **Repository:** https://github.com/rrwood/docker-dev-build
- **Issues:** Check documentation first, then open GitHub issue
- **Updates:** `docker builder prune -a -f` then redeploy in Portainer

## Version

**Latest Commit:** Check `git log --oneline -1` for current version

**Key Feature:** CONTAINER_HOSTNAME support (fixes Portainer hostname issue)

---

**Status:** ✅ Production Ready

**Last Updated:** 2026-04-27

# Deployment Checklist for Portainer

## Your Environment File

**File:** `rw.home.env` (on local machine, not in git)

**Contents:**
```bash
USERNAME=rwood
USER_PASSWORD=m3bas303
CONTAINER_NAME=docker-dev
CONTAINER_HOSTNAME=docker-dev    # ✅ Fixed - was HOSTNAME
CONTAINER_IP=192.168.111.15
WORKSPACE_PATH=./workspace
TIMEZONE=UTC
INSTALL_NGROK=false
GITHUB_REPO=https://github.com/rrwood/docker-dev-build.git
GITHUB_BRANCH=main
```

## Deployment Steps

### 1. Clear Docker Cache (You're doing this)

```bash
# On Portainer host
docker stop docker-dev 2>/dev/null
docker rm docker-dev 2>/dev/null
docker images | grep docker-dev | awk '{print $3}' | xargs -r docker rmi -f
docker builder prune -a -f
```

### 2. Deploy in Portainer

**Stack Settings:**
- Name: `docker-dev`
- Build method: **Git Repository**
- Repository URL: `https://github.com/rrwood/docker-dev-build`
- Repository reference: `refs/heads/main`
- Compose path: `docker-compose.yml`

**Environment Variables:**
- Load variables from .env file: `rw.home.env`

**OR manually add (if env file doesn't work):**
```
USERNAME=rwood
USER_PASSWORD=m3bas303
CONTAINER_NAME=docker-dev
CONTAINER_HOSTNAME=docker-dev    ← Key variable!
CONTAINER_IP=192.168.111.15
WORKSPACE_PATH=./workspace
TIMEZONE=UTC
```

### 3. Deploy the Stack

Click **Deploy the stack** and wait for build to complete.

### 4. Verify Hostname Works

```bash
# SSH into container
ssh rwood@192.168.111.15

# Run diagnostic
~/setup/verify-env.sh
```

**Expected output:**
```
HOSTNAME (from build):     docker-dev        ✅
hostname (runtime):        docker-dev        ✅
BUILD_HOSTNAME (env):      docker-dev        ✅
USERNAME:                  rwood             ✅
```

**If still wrong:**
```
HOSTNAME (from build):     42420cabd961      ❌
BUILD_HOSTNAME (env):      [not set]         ❌
```

This means env file wasn't loaded - set variables manually in Portainer UI.

### 5. Setup SSH Keys

Once hostname is working:

```bash
# From your Windows machine (PowerShell)
type ~\.ssh\id_rsa.pub | ssh rwood@192.168.111.15 "cat >> ~/.ssh/authorized_keys"

# Or from Linux/Mac
ssh-copy-id rwood@192.168.111.15
```

### 6. Change Password

```bash
# Inside container
cd ~/setup
./change-password.sh
```

### 7. Optional - Install Claude CLI

```bash
# Inside container
~/setup/setup-claude.sh
```

## Troubleshooting

### Hostname Still Random

**Check 1: Is env file being loaded?**

In Portainer, verify the env file path is exactly: `rw.home.env`

**Check 2: Does env file exist in GitHub?**

No! Your `rw.home.env` is gitignored (correct - has password).

Portainer won't find it in the repo.

**Solution: Set variables manually in Portainer UI**

Click "+ add an environment variable" for each variable instead of using env file.

### Can't SSH

**Check container is running:**
```bash
docker ps | grep docker-dev
```

**Check SSH service:**
```bash
docker exec docker-dev rc-service sshd status
```

**Test connectivity:**
```bash
ping 192.168.111.15
telnet 192.168.111.15 22
```

### Scripts Not Appearing

Cached build. Clear cache again:
```bash
docker builder prune -a -f
```

## Success Criteria

- [ ] Container hostname is `docker-dev` (not container ID)
- [ ] Can SSH with: `ssh rwood@192.168.111.15`
- [ ] Scripts exist: `ls ~/setup/verify-env.sh`
- [ ] Diagnostic shows all variables correct
- [ ] SSH keys work (password-less login)

## Quick Reference

**Your container:**
- Username: `rwood`
- Password: `m3bas303` (change after login!)
- IP: `192.168.111.15`
- Hostname: `docker-dev` (should be)

**Important files:**
- Local env file: `C:\Users\rwood\code\devserverdocker\rw.home.env`
- In Portainer: Specify as `rw.home.env`

**Key variable:**
- `CONTAINER_HOSTNAME=docker-dev` (NOT HOSTNAME!)

---

Good luck! 🚀

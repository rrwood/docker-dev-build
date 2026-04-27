# HOSTNAME is Reserved by Portainer - Use CONTAINER_HOSTNAME Instead

## The Issue We Discovered

**Symptoms:**
- `USERNAME=rwood` from env file ✅ Works
- `CONTAINER_IP=192.168.111.15` from env file ✅ Works  
- `HOSTNAME=docker-dev` from env file ❌ **Doesn't work**
- Container gets random hostname like `42420cabd961`

**Root Cause:**

`HOSTNAME` is a **reserved environment variable** in Docker/Portainer. When Portainer reads your env file:

1. ✅ It reads `USERNAME` and passes it correctly
2. ✅ It reads `CONTAINER_IP` and passes it correctly
3. ❌ It reads `HOSTNAME` but **doesn't substitute it** in the `hostname:` field
4. ❌ Docker falls back to using container ID as hostname

This is a known limitation/bug in how Portainer handles the `hostname:` field in docker-compose.yml.

## The Solution

**Use `CONTAINER_HOSTNAME` instead of `HOSTNAME`**

### Step 1: Update Your env.rw.home File

Change this line:
```bash
# OLD (doesn't work):
HOSTNAME=docker-dev

# NEW (works):
CONTAINER_HOSTNAME=docker-dev
```

Your complete `env.rw.home` should look like:

```bash
# Container Configuration
USERNAME=rwood
USER_PASSWORD=m3bas303
CONTAINER_NAME=docker-dev
CONTAINER_HOSTNAME=docker-dev    # ← Changed from HOSTNAME
CONTAINER_IP=192.168.111.15

# Workspace Configuration
WORKSPACE_PATH=./workspace
TIMEZONE=UTC

# Optional
INSTALL_NGROK=false
NGROK_AUTH_TOKEN=

# GitHub Repository Configuration
GITHUB_REPO=https://github.com/rrwood/docker-dev-build.git
GITHUB_BRANCH=main
```

### Step 2: Purge and Redeploy

Since you need to rebuild with the new variable:

**On Portainer host:**
```bash
docker stop docker-dev
docker rm docker-dev
docker images | grep docker-dev | awk '{print $3}' | xargs -r docker rmi -f
docker builder prune -a -f
```

**In Portainer:**
1. Delete existing stack
2. Create new stack from Git
3. Use env file: `env.rw.home`
4. Deploy

### Step 3: Verify It Worked

```bash
ssh rwood@192.168.111.15
~/setup/verify-env.sh
```

**Expected output:**
```
HOSTNAME (from build):     docker-dev        ✅
hostname (runtime):        docker-dev        ✅
BUILD_HOSTNAME (env):      docker-dev        ✅
✅ CONTAINER_HOSTNAME env var matches runtime: docker-dev
```

---

## Why This Happens

### Reserved Variables in Docker

Docker reserves certain environment variables:

| Variable | Reserved? | Works in docker-compose? |
|----------|-----------|--------------------------|
| `HOSTNAME` | ✅ Yes | ❌ No - Docker overrides |
| `PATH` | ✅ Yes | ❌ No - System managed |
| `HOME` | ✅ Yes | ❌ No - System managed |
| `USER` | ✅ Yes | ⚠️ Sometimes |
| `CONTAINER_HOSTNAME` | ❌ No | ✅ Yes - Custom var |

When you set `HOSTNAME=docker-dev` in your env file:
1. Docker/Portainer sees it
2. But Docker's runtime **overrides** it with the container ID
3. Your value is ignored

When you set `CONTAINER_HOSTNAME=docker-dev`:
1. This is a **custom** variable (not reserved)
2. docker-compose substitutes it: `hostname: ${CONTAINER_HOSTNAME:-docker-dev}`
3. Docker respects it ✅

---

## Updated docker-compose.yml

The repository now uses `CONTAINER_HOSTNAME`:

```yaml
services:
  docker-dev:
    build:
      context: .
      args:
        CONTAINER_HOSTNAME: ${CONTAINER_HOSTNAME:-docker-dev}  # Changed
    hostname: "${CONTAINER_HOSTNAME:-docker-dev}"              # Changed
    environment:
      - BUILD_HOSTNAME=${CONTAINER_HOSTNAME:-docker-dev}       # For diagnostics
```

---

## Migration Guide

### If You're Using .env.example

**Old:**
```bash
HOSTNAME=docker-dev
```

**New:**
```bash
CONTAINER_HOSTNAME=docker-dev
```

### If You're Using portainer.env

Already updated in the repository! ✅

### If You're Using env.rw.home (Your Case)

**Edit your file:**
```bash
nano env.rw.home

# Change:
# HOSTNAME=docker-dev
# To:
CONTAINER_HOSTNAME=docker-dev
```

**Save and redeploy:**
```bash
# Purge cache
docker builder prune -a -f

# Redeploy in Portainer
```

---

## Diagnostic Tool

The `verify-env.sh` script now checks for `BUILD_HOSTNAME`:

```bash
~/setup/verify-env.sh
```

**If you see:**
```
BUILD_HOSTNAME (env):      [not set]
```

**It means:**
- You're still using `HOSTNAME` in your env file
- Change it to `CONTAINER_HOSTNAME`
- Redeploy

**If you see:**
```
BUILD_HOSTNAME (env):      docker-dev
hostname (runtime):        docker-dev
✅ CONTAINER_HOSTNAME env var matches runtime: docker-dev
```

**It means:**
- ✅ Working correctly!
- Your custom hostname is applied

---

## Quick Fix Checklist

- [ ] Edit `env.rw.home`: Change `HOSTNAME=` to `CONTAINER_HOSTNAME=`
- [ ] Save the file
- [ ] Purge Docker cache: `docker builder prune -a -f`
- [ ] Remove old stack in Portainer
- [ ] Deploy new stack in Portainer
- [ ] SSH in and run: `~/setup/verify-env.sh`
- [ ] Verify hostname shows your custom value

---

## Why We Didn't See This Before

**Testing scenario:**
- Most people test locally with `docker-compose up`
- Local docker-compose DOES substitute `${HOSTNAME}` correctly
- Bug only appears in **Portainer** specifically
- Portainer has different environment variable handling

**Your setup:**
- Using Portainer with env file
- Portainer has special handling for reserved vars
- `HOSTNAME` is treated specially (and incorrectly)

---

## Summary

**Problem:**
```
HOSTNAME is reserved → Portainer doesn't substitute it → Random hostname
```

**Solution:**
```
Use CONTAINER_HOSTNAME instead → Not reserved → Works! ✅
```

**Action:**
```bash
# In env.rw.home:
CONTAINER_HOSTNAME=docker-dev  # Not HOSTNAME

# Redeploy → Profit! 🎉
```

---

**This should finally fix your hostname issue!** 🚀

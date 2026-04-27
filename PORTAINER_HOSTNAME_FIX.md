# Portainer Hostname Issue - COMPLETE FIX

## The Problem

Your container hostname is random (like `42420cabd961`) instead of your custom hostname.

**Example:**
```bash
hostname
# Shows: 42420cabd961
# Expected: my-dev-box
```

## Root Cause

The `HOSTNAME` environment variable is **NOT SET** in your Portainer stack configuration.

Without it, Docker uses the container ID as the hostname.

## The Solution (Step-by-Step)

### Step 1: Check Current Environment Variables in Portainer

1. **In Portainer UI:**
   - Go to: **Stacks** → **your-stack-name**
   - Click: **Editor** tab
   - Scroll down to: **Environment variables** section

2. **Look for this variable:**
   ```
   HOSTNAME=your-hostname-here
   ```

3. **Is it there?**
   - ✅ **YES** → Go to Step 2 (it's set but not applying)
   - ❌ **NO** → This is your problem! Add it in Step 2.

### Step 2: Add/Fix the HOSTNAME Variable

**In the Portainer Environment Variables section, you MUST have:**

```
USERNAME=devuser
USER_PASSWORD=changeme123
CONTAINER_NAME=docker-dev
HOSTNAME=my-dev-box          ← THIS IS CRITICAL!
CONTAINER_IP=192.168.111.15
WORKSPACE_PATH=./workspace
TIMEZONE=UTC
```

**Click each line to add:**
- **Name:** `HOSTNAME`
- **Value:** `my-dev-box` (or whatever you want)

### Step 3: Force Complete Rebuild

Just updating the variable **won't fix existing containers**. You MUST rebuild:

#### Option A: In Portainer UI (Easiest)

1. **Stop the stack:**
   - Stacks → your-stack → **Stop**

2. **Remove the stack:**
   - Stacks → your-stack → **Remove**
   - ⚠️ Check "Remove associated volumes" **ONLY** if you want fresh data!

3. **Wait 10 seconds**

4. **Deploy new stack:**
   - Stacks → **Add stack**
   - Name: `docker-dev` (or whatever)
   - Build method: **Git Repository**
   - Repository URL: `https://github.com/rrwood/docker-dev-build`
   - Reference: `refs/heads/main`
   - Compose path: `docker-compose.yml`

5. **Add ALL environment variables:**
   ```
   USERNAME=devuser
   USER_PASSWORD=YourSecurePassword123
   CONTAINER_NAME=docker-dev
   HOSTNAME=my-dev-box          ← DON'T FORGET THIS!
   CONTAINER_IP=192.168.111.15
   WORKSPACE_PATH=./workspace
   TIMEZONE=America/New_York
   INSTALL_NGROK=false
   ```

6. **Deploy the stack**

#### Option B: SSH to Portainer Host (Advanced)

```bash
# SSH to your Portainer host machine

# Remove old container
docker stop docker-dev
docker rm docker-dev

# Remove old image
docker images | grep docker-dev | awk '{print $3}' | xargs docker rmi -f

# Clear build cache
docker builder prune -a -f

# Go back to Portainer UI and redeploy with HOSTNAME set
```

### Step 4: Verify It Worked

```bash
# SSH into your new container
ssh devuser@192.168.111.15

# Check hostname
hostname
# Should show: my-dev-box (or whatever you set)

# Also check /etc/hostname
cat /etc/hostname
# Should show: my-dev-box

# Check shell prompt
# Should show: devuser@my-dev-box:~$
```

## Why This Happens

Docker sets the container hostname from **two sources** (in this order):

1. **Runtime:** `hostname:` field in docker-compose.yml
   - In our case: `hostname: ${HOSTNAME:-docker-dev}`
   - This reads the `HOSTNAME` environment variable
   - If not set, defaults to `docker-dev`

2. **If still not set:** Uses container ID as hostname
   - Results in random names like `42420cabd961`

**The fix:** Set `HOSTNAME` environment variable in Portainer!

## Checklist Before Deploying

Before you click "Deploy the stack", verify you have ALL these:

```
✅ USERNAME=devuser
✅ USER_PASSWORD=changeme123
✅ CONTAINER_NAME=docker-dev
✅ HOSTNAME=my-dev-box           ← MOST IMPORTANT!
✅ CONTAINER_IP=192.168.111.15
✅ WORKSPACE_PATH=./workspace
✅ TIMEZONE=UTC or America/New_York
```

## Common Mistakes

### ❌ Mistake 1: Setting hostname AFTER deployment

Setting the variable after the container is created won't change the existing container. You MUST redeploy.

### ❌ Mistake 2: Using "Pull and redeploy"

This might use cached layers. Use "Stop → Remove → Deploy new" instead.

### ❌ Mistake 3: Typo in variable name

Must be exactly: `HOSTNAME` (all caps, no spaces)

Not: `hostname`, `Hostname`, `HOST_NAME`, etc.

### ❌ Mistake 4: Setting it in .env file but not Portainer

If using Portainer, the .env file **in your local directory** doesn't matter.

You MUST set it **in Portainer's Environment Variables section**.

## Testing Before Full Deployment

Want to test first?

**Create a test stack:**

1. **New stack name:** `docker-dev-test`
2. **Add all variables (including HOSTNAME)**
3. **Deploy**
4. **SSH in and verify hostname**
5. **If it works, delete test stack and create real one**

## Quick Diagnosis

Run this inside your container:

```bash
# Check what hostname should be (from build)
cat /etc/hostname

# Check what hostname actually is (from Docker)
hostname

# Check if they match
if [ "$(cat /etc/hostname)" = "$(hostname)" ]; then
    echo "✅ Hostname is correct!"
else
    echo "❌ Hostname mismatch - HOSTNAME env var not set in Portainer"
fi
```

## The set-hostname.sh Script

I've updated this script to be **informational only**.

It will:
- ✅ Show current hostname
- ✅ Explain why you can't change it from inside container
- ✅ Show instructions to fix in Portainer
- ✅ Detect mismatches

It will **NOT** try to change the hostname (this is impossible in Docker without special capabilities).

## Summary

**Problem:** Random hostname like `42420cabd961`  
**Cause:** `HOSTNAME` environment variable not set in Portainer  
**Fix:** Set `HOSTNAME=my-dev-box` in Portainer environment variables and redeploy  

**That's it!** 🎉

---

**Still having issues?** Check the full troubleshooting guide: TROUBLESHOOTING_PORTAINER.md

# Portainer Complete Cache Purge Guide

## Problem

After "Pull and redeploy", new scripts/changes from GitHub aren't appearing in the container.

**Cause:** Portainer/Docker is using cached build layers, cached git clone, or cached images.

## Complete Purge Steps

### Method 1: Portainer UI + SSH (Most Thorough)

#### Step 1: Stop and Remove in Portainer

1. **In Portainer UI:**
   - Go to: **Stacks** → **your-stack-name**
   - Click: **Stop**
   - Wait for it to fully stop
   - Click: **Remove**
   - ⚠️ **Uncheck** "Remove associated volumes" (unless you want to lose data)
   - Confirm removal

#### Step 2: SSH to Portainer Host and Purge Everything

```bash
# SSH to your Portainer host machine
ssh user@portainer-host

# 1. Remove ALL docker-dev related images
docker images | grep docker-dev
docker images | grep docker-dev | awk '{print $3}' | xargs -r docker rmi -f

# 2. Clear ALL build cache (this is critical!)
docker builder prune -a -f

# 3. Optional: Clear system cache (removes all unused images)
docker system prune -a -f

# 4. Verify everything is gone
docker images | grep docker-dev
# Should return nothing
```

#### Step 3: Redeploy in Portainer

1. **In Portainer UI:**
   - Stacks → **Add stack**
   - Name: `docker-dev` (or whatever you want)
   - Build method: **Git Repository**
   - Repository URL: `https://github.com/rrwood/docker-dev-build`
   - Repository reference: `refs/heads/main`
   - Compose path: `docker-compose.yml`
   
2. **Set env file path:**
   - Advanced mode → Environment variables
   - Load variables from .env file: `env.rw.home`
   
   **OR set manually:**
   ```
   USERNAME=rwood
   USER_PASSWORD=m3bas303
   HOSTNAME=docker-dev
   CONTAINER_NAME=docker-dev
   CONTAINER_IP=192.168.111.15
   ```

3. **Deploy the stack**

4. **Wait for build to complete** (will take longer - fresh build)

5. **Verify:**
   ```bash
   ssh rwood@192.168.111.15
   ls ~/setup/verify-env.sh
   # Should exist now!
   ```

---

### Method 2: Nuclear Option (If Method 1 Doesn't Work)

If you're still getting cached stuff:

```bash
# SSH to Portainer host

# Stop ALL containers (if you can)
docker stop $(docker ps -aq)

# Remove ALL containers
docker rm $(docker ps -aq)

# Remove ALL images
docker rmi -f $(docker images -q)

# Remove ALL build cache
docker builder prune -a -f

# Remove unused volumes (CAREFUL - only if you know what you're doing)
docker volume prune -f

# Clean everything
docker system prune -a -f --volumes

# Verify nothing left
docker ps -a
docker images
```

Then redeploy in Portainer.

⚠️ **WARNING:** This removes EVERYTHING from Docker. Only use if this is a dedicated Portainer host.

---

### Method 3: Just Cache (Less Destructive)

If you only want to clear cache but keep existing containers:

```bash
# SSH to Portainer host

# Clear build cache only
docker builder prune -a -f

# Clear dangling images
docker image prune -a -f

# Clear build kit cache (if using buildkit)
docker buildx prune -a -f
```

Then in Portainer: Stop → Remove → Deploy

---

## Verification Checklist

After redeploying, verify everything is fresh:

```bash
# SSH into container
ssh rwood@192.168.111.15

# 1. Check new script exists
ls -la ~/setup/verify-env.sh
# If exists: ✅ Fresh build worked

# 2. Run it
~/setup/verify-env.sh

# 3. Check other new scripts
ls -la ~/setup/
# Should show: verify-env.sh among others

# 4. Check git commit in image (if we add this)
cat /etc/os-release
```

---

## Common Issues

### Issue 1: "Image in use" Error

```
Error: image is being used by running container
```

**Fix:**
```bash
# Force stop
docker stop docker-dev
docker rm docker-dev

# Then try removing image again
docker rmi -f IMAGE_ID
```

### Issue 2: Still Getting Old Container

**Check if wrong image is being used:**

```bash
# List all images with docker-dev
docker images | grep docker-dev

# You might see multiple:
# docker-dev_docker-dev  latest  abc123  (old)
# docker-dev_docker-dev  latest  def456  (old)

# Remove ALL of them
docker images | grep docker-dev | awk '{print $3}' | xargs docker rmi -f
```

### Issue 3: Portainer Not Pulling Latest from GitHub

**Force Portainer to re-clone:**

Portainer caches git clones. To force fresh clone:

1. **Change repository URL slightly:**
   - Instead of: `https://github.com/rrwood/docker-dev-build`
   - Use: `https://github.com/rrwood/docker-dev-build.git` (add .git)
   - Or vice versa

2. **Or change branch then change back:**
   - First deploy with: `refs/heads/develop` (any other branch)
   - Then redeploy with: `refs/heads/main`

3. **Or use commit hash:**
   - Get latest commit: `git log --oneline -1`
   - Use: `refs/heads/92883c9` (or whatever the latest commit is)

---

## Quick Reference Commands

**See what's cached:**
```bash
# Show all docker-dev images
docker images | grep docker-dev

# Show build cache
docker system df

# Show detailed build cache
docker buildx du
```

**Clear specific things:**
```bash
# Clear only build cache
docker builder prune -a -f

# Clear only images
docker image prune -a -f

# Clear everything
docker system prune -a -f --volumes
```

**Check what's running:**
```bash
# All containers
docker ps -a

# Just docker-dev
docker ps | grep docker-dev

# Get container details
docker inspect docker-dev
```

---

## Why "Pull and Redeploy" Doesn't Work

**What "Pull and redeploy" does:**
1. ✅ Pulls latest docker-compose.yml from git
2. ✅ Pulls latest Dockerfile from git
3. ❌ **STILL USES CACHED BUILD LAYERS**
4. ❌ **Doesn't clear git clone cache**

**Result:** You get the new Dockerfile instructions, but Docker says "I already ran this RUN command before, skip it" and uses old cached layer.

**What you need to do:**
1. **Stop and Remove** (not just stop)
2. **Clear build cache** on host
3. **Deploy fresh** (not redeploy)

This forces Docker to run every RUN command fresh, including git clone.

---

## Script for Complete Purge

Save this on your Portainer host:

```bash
#!/bin/bash
# purge-docker-dev.sh
# Complete purge of docker-dev stack

echo "Stopping containers..."
docker stop docker-dev 2>/dev/null

echo "Removing containers..."
docker rm docker-dev 2>/dev/null

echo "Removing images..."
docker images | grep docker-dev | awk '{print $3}' | xargs -r docker rmi -f

echo "Clearing build cache..."
docker builder prune -a -f

echo "Clearing system cache..."
docker system prune -f

echo ""
echo "✅ Purge complete!"
echo ""
echo "Now redeploy in Portainer UI"
```

**Usage:**
```bash
chmod +x purge-docker-dev.sh
./purge-docker-dev.sh
# Then go to Portainer and deploy
```

---

## Prevention

To avoid this in future:

1. **Always use "Stop → Remove → Deploy"** not "Redeploy"

2. **Run cache clear before major updates:**
   ```bash
   docker builder prune -a -f
   ```

3. **Use specific git commit hashes** in Portainer for critical deployments:
   - Instead of: `refs/heads/main`
   - Use: `refs/heads/92883c9`
   - Forces fresh pull when commit changes

4. **Add build arg to force cache busting:**
   We could add `BUILD_DATE` arg that changes each build

---

## Summary

**Your current issue:**
```
Portainer → Pull and redeploy → Uses cached layers → Old scripts
```

**The fix:**
```
1. Portainer → Stop → Remove
2. SSH to host → docker builder prune -a -f
3. Portainer → Deploy fresh
4. Get new scripts ✅
```

**Do this now:**

```bash
# On Portainer host:
ssh user@portainer-host
docker stop docker-dev
docker rm docker-dev
docker images | grep docker-dev | awk '{print $3}' | xargs docker rmi -f
docker builder prune -a -f
echo "✅ Ready for fresh deploy in Portainer!"
```

Then deploy in Portainer UI!

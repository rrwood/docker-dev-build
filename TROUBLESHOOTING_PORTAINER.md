# Portainer Deployment Troubleshooting

## Hostname Still Random After Redeploy

### Problem
After setting `HOSTNAME=my-hostname` in Portainer environment variables and redeploying, the container still has a random hostname.

### Root Cause
Portainer may be using **cached Docker build layers**, which means the old hostname (or default) is baked into the cached image.

### Solution 1: Force Rebuild (Recommended)

**In Portainer:**

1. **Stop and Remove the Stack:**
   - Stacks → docker-dev → **Stop**
   - Stacks → docker-dev → **Remove**
   - Check "Remove associated volumes" if you want fresh start (⚠️ **will delete data!**)

2. **Clear Build Cache (Important!):**
   ```bash
   # On the Portainer host machine, run:
   docker builder prune -a -f
   ```

3. **Redeploy Stack:**
   - Stacks → Add stack
   - Git Repository: `https://github.com/rrwood/docker-dev-build`
   - Reference: `refs/heads/main`
   - Add environment variables (especially `HOSTNAME=your-hostname`)
   - Deploy

4. **Verify:**
   ```bash
   # SSH into container
   ssh devuser@192.168.111.15
   
   # Check hostname
   hostname
   # Should show: your-hostname
   ```

### Solution 2: Use Different Stack Name

If you don't want to delete the existing stack:

1. **Deploy with a NEW stack name:**
   - Stack name: `docker-dev-v2` (or anything different)
   - This forces a fresh build

2. **After verifying it works, delete the old stack**

### Solution 3: Manual Docker Build on Host

**On the Portainer host machine:**

```bash
# Clone repo
git clone https://github.com/rrwood/docker-dev-build.git
cd docker-dev-build

# Create .env file
cat > .env << EOF
USERNAME=devuser
USER_PASSWORD=YourSecurePassword
HOSTNAME=my-custom-hostname
CONTAINER_NAME=docker-dev
CONTAINER_IP=192.168.111.15
EOF

# Force rebuild without cache
docker-compose build --no-cache

# Start
docker-compose up -d

# Verify
docker exec docker-dev hostname
# Should show: my-custom-hostname
```

---

## Setup Scripts Not Appearing in ~/setup/

### Problem
After redeploying, the `~/setup/` directory is empty or doesn't have the new scripts (like `set-hostname.sh`).

### Root Cause
1. **Cached build layers** - Docker is using old cached image
2. **Git not pulling latest** - Portainer might have cached the git clone

### Solution

**Force Complete Rebuild:**

1. **In Portainer:**
   - Stop and remove stack completely
   - Wait 30 seconds

2. **On Portainer host, clear ALL caches:**
   ```bash
   # Clear build cache
   docker builder prune -a -f
   
   # Remove old images
   docker images | grep docker-dev | awk '{print $3}' | xargs docker rmi -f
   
   # Clear unused volumes (⚠️ CAREFUL - backs up data first!)
   docker volume ls | grep docker-dev
   ```

3. **Redeploy in Portainer** (fresh build will pull latest from GitHub)

4. **Verify scripts exist:**
   ```bash
   docker exec docker-dev ls -la /home/devuser/setup/
   # Should show: change-password.sh, generate-ssh-keys.sh, set-hostname.sh, etc.
   ```

---

## Environment Variables Not Being Used

### Problem
Set environment variables in Portainer but container uses defaults.

### Check 1: Verify Variables Are Set

**In Portainer:**
- Stacks → docker-dev → Editor
- Scroll down to "Environment variables" section
- Verify variables are listed:
  ```
  USERNAME=devuser
  HOSTNAME=my-hostname
  CONTAINER_IP=192.168.111.15
  etc.
  ```

### Check 2: Check Build Args Are Passed

The environment variables must be passed to the build process. Verify `docker-compose.yml`:

```yaml
build:
  args:
    USERNAME: ${USERNAME:-devuser}
    CONTAINER_HOSTNAME: ${HOSTNAME:-docker-dev}
```

If `CONTAINER_HOSTNAME` is missing, the latest code from GitHub has it. Redeploy.

### Check 3: Inspect Running Container

```bash
# On Portainer host
docker inspect docker-dev | grep -A10 Config

# Check hostname specifically
docker inspect docker-dev | grep Hostname
```

Should show your custom hostname, not a random one.

---

## Build Fails When Pulling from GitHub

### Problem
```
fatal: could not read Username for 'https://github.com': No such device or address
```

### Solution
Make sure the repository is **public**.

1. Go to: https://github.com/rrwood/docker-dev-build
2. Settings → General → Danger Zone
3. Change visibility → Public

---

## Portainer Shows "Build Failed" But No Error

### Check Build Logs

**In Portainer:**
1. Stacks → docker-dev → Build logs
2. Look for actual error message
3. Common issues:
   - Network timeout pulling from GitHub
   - Docker cache corruption
   - Insufficient disk space

### Solution: Clear Everything and Rebuild

```bash
# On Portainer host
docker system prune -a --volumes -f
# ⚠️ WARNING: This removes ALL unused Docker data!

# Then redeploy in Portainer
```

---

## Container Starts But Can't SSH

### Check 1: Container is Running

```bash
docker ps | grep docker-dev
# Should show container running on port 22
```

### Check 2: Network is Correct

```bash
docker inspect docker-dev | grep -A10 Networks
# Should show macvlan network with your IP
```

### Check 3: SSH Service is Running

```bash
docker exec docker-dev rc-service sshd status
# Should show: sshd is running

# If not running:
docker exec docker-dev rc-service sshd start
```

### Check 4: Firewall

```bash
# Test if port 22 is reachable
telnet 192.168.111.15 22

# Or
nc -zv 192.168.111.15 22
```

---

## Debugging Checklist

Run these commands to gather debug info:

```bash
# On Portainer host:

# 1. Check if container is running
docker ps | grep docker-dev

# 2. Check container hostname
docker exec docker-dev hostname

# 3. Check /etc/hostname inside container
docker exec docker-dev cat /etc/hostname

# 4. Check environment variables passed to container
docker inspect docker-dev | grep -A20 Env

# 5. Check setup scripts exist
docker exec docker-dev ls -la /home/devuser/setup/

# 6. Check git commit hash in image
docker exec docker-dev ls -la /tmp/ 2>/dev/null || echo "Cleaned up (normal)"

# 7. Check build args that were used
docker inspect docker-dev | grep -A10 Labels
```

---

## Quick Fix Commands

### Force Rebuild Everything

```bash
# On Portainer host:

# Stop container
docker stop docker-dev

# Remove container
docker rm docker-dev

# Remove image
docker rmi docker-dev_docker-dev

# Clear build cache
docker builder prune -a -f

# Now redeploy in Portainer UI
```

### Check What Hostname Will Be Used

```bash
# On Portainer host, in the project directory:

# Check .env file
cat .env | grep HOSTNAME

# Check what docker-compose will use
docker-compose config | grep hostname
```

---

## Still Not Working?

### Collect This Information:

1. **Output of hostname check:**
   ```bash
   docker exec docker-dev hostname
   ```

2. **Environment variables:**
   ```bash
   docker inspect docker-dev | grep -A20 Env
   ```

3. **Build logs from Portainer:**
   - Copy the full build log output

4. **Stack configuration:**
   - Copy your environment variables from Portainer

5. **Docker version:**
   ```bash
   docker version
   ```

6. **Portainer version:**
   - Check in Portainer UI → Settings

### Then:
- Check GitHub issues: https://github.com/rrwood/docker-dev-build/issues
- Or post in container logs to troubleshoot

---

## Prevention Tips

1. **Always set environment variables BEFORE first deployment**
   - Don't rely on defaults if you want custom values

2. **Use unique hostnames**
   - Makes it easier to identify containers

3. **Force rebuild after repository updates**
   - Use "Stop → Remove → Deploy" instead of just "Redeploy"
   - Or run `docker builder prune -a -f` before redeploying

4. **Document your environment variables**
   - Keep a copy of your Portainer env vars in a safe place

5. **Test in local docker-compose first**
   - Before deploying to Portainer, test locally:
   ```bash
   git clone https://github.com/rrwood/docker-dev-build.git
   cd docker-dev-build
   cp .env.example .env
   nano .env  # Set your values
   docker-compose build --no-cache
   docker-compose up -d
   docker exec docker-dev hostname  # Verify
   ```

---

**Need more help?** Check SSH_SETUP_GUIDE.md and PORTAINER_DEPLOY.md

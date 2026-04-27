# Hostname Configuration Fix

## Problem
Hostname was not picking up the value from the environment variable - containers were getting default/random hostnames.

## Solution Implemented

### 1. Hostname Set During Build (Dockerfile)
```dockerfile
ARG CONTAINER_HOSTNAME=docker-dev
RUN echo "${CONTAINER_HOSTNAME}" > /etc/hostname
```

### 2. Hostname Set at Runtime (docker-compose.yml)
```yaml
hostname: ${HOSTNAME:-docker-dev}
```

### 3. Hostname Passed as Build Argument
```yaml
build:
  args:
    CONTAINER_HOSTNAME: ${HOSTNAME:-docker-dev}
```

## How It Works Now

**During Build:**
1. `HOSTNAME` environment variable from `.env` file (or Portainer)
2. Passed to Dockerfile as `CONTAINER_HOSTNAME` build arg
3. Written to `/etc/hostname` inside the image

**At Runtime:**
1. Docker sets container hostname from `hostname:` field in compose
2. Container reads `/etc/hostname` on boot
3. Hostname is now consistent and matches your configuration

## Configuration

### In Portainer

Set the `HOSTNAME` environment variable:
```
HOSTNAME=my-dev-box
```

### In .env file

```env
HOSTNAME=my-dev-box
```

### Verification

After deploying:

```bash
# SSH into container
ssh devuser@192.168.111.15

# Check hostname
hostname
# Should show: my-dev-box (or whatever you set)

# Verify in shell prompt
# Should show: devuser@my-dev-box:~$
```

## Changing Hostname After Deployment

If you need to change the hostname after the container is already deployed:

### Option 1: Update and Redeploy (Recommended)

1. **Update environment variable in Portainer:**
   - Stacks → docker-dev → Environment variables
   - Change `HOSTNAME=new-hostname`

2. **Redeploy:**
   - Stacks → docker-dev → Pull and redeploy

### Option 2: Manual Change (Temporary)

Inside the container, use the helper script:

```bash
cd ~/setup
sudo ./set-hostname.sh
```

**Note:** This change will **not persist** across container restarts unless you also update the environment variable in Portainer.

## Troubleshooting

### Hostname still showing as default

**Check environment variable is set:**
```bash
# On host (where docker-compose.yml is)
grep HOSTNAME .env
# or in Portainer: View environment variables
```

**Rebuild the container:**
```bash
# In Portainer
Stacks → docker-dev → Stop
Stacks → docker-dev → Remove
Stacks → docker-dev → Deploy
```

### Hostname shows correctly but prompt doesn't

The shell prompt might be cached. Update it:

```bash
# Inside container
source ~/.bashrc

# Or logout and login again
exit
ssh devuser@192.168.111.15
```

### Different hostname in different places

**Check all three locations:**

```bash
# 1. Docker's hostname setting
docker inspect docker-dev | grep Hostname

# 2. Inside /etc/hostname
docker exec docker-dev cat /etc/hostname

# 3. Runtime hostname command
docker exec docker-dev hostname
```

All three should match. If not, redeploy with clean build:

```bash
# In Portainer
Stop and remove stack
Deploy stack (will rebuild from scratch)
```

## New Helper Script

Added `setup/set-hostname.sh` for changing hostname post-deployment:

```bash
cd ~/setup
sudo ./set-hostname.sh
```

This script:
- Updates `/etc/hostname`
- Updates `/etc/hosts`
- Applies change immediately
- Warns that it won't persist without updating Portainer config

## Testing

After implementing this fix, test with:

```bash
# Set HOSTNAME in Portainer to: test-hostname
# Deploy stack
# SSH into container
hostname
# Should output: test-hostname
```

---

**Status:** ✅ Fixed in commit 860ccef and later

**Files Modified:**
- `Dockerfile` - Added CONTAINER_HOSTNAME build arg and /etc/hostname setup
- `docker-compose.yml` - Pass HOSTNAME as CONTAINER_HOSTNAME build arg
- `setup/set-hostname.sh` - New helper script for post-deployment changes
- Documentation updated

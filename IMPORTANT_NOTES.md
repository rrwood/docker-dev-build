# ⚠️ IMPORTANT NOTES - READ FIRST!

## Critical Configuration Issue - SOLVED

### The Problem
`HOSTNAME` is a **reserved environment variable** in Docker/Portainer. If you set:
```env
HOSTNAME=docker-dev
```

It will **NOT work**. Your container will get a random hostname like `42420cabd961`.

### ✅ The Solution
Use `CONTAINER_HOSTNAME` instead:
```env
CONTAINER_HOSTNAME=docker-dev
```

**This is the ONLY way to set a custom hostname in Portainer!**

---

## Environment Variables in Portainer

### What Works
✅ Setting variables **manually in Portainer UI** (recommended)
✅ Using `portainer.env` file (committed to repo, has safe defaults)

### What Doesn't Work
❌ Using custom env file like `rw.home.env` (gitignored, not in repo)
❌ Using `.env` file (gitignored, not in repo)

**Why?** Portainer clones from GitHub. If the env file is gitignored, it won't be in the repo for Portainer to read.

**Solution:** Set variables manually in Portainer UI when creating the stack.

---

## Required Environment Variables

```env
USERNAME=your-username                  # Container user
USER_PASSWORD=your-secure-password     # Initial password (CHANGE AFTER DEPLOYMENT!)
CONTAINER_NAME=docker-dev              # Container name in Docker
CONTAINER_HOSTNAME=your-hostname       # Container hostname (NOT HOSTNAME!)
CONTAINER_IP=192.168.111.15           # Static IP address
WORKSPACE_PATH=./workspace             # Volume mount path
TIMEZONE=UTC                           # Container timezone
```

---

## Portainer Cache Issues

### Symptom
After "Pull and redeploy", new scripts/changes don't appear.

### Cause
Docker is using cached build layers.

### Solution
```bash
# SSH to Portainer host
docker builder prune -a -f

# Then in Portainer: Stop → Remove → Deploy (not just redeploy)
```

---

## First Login Checklist

After deploying, SSH into the container:

```bash
ssh username@container-ip
```

Then run these setup scripts (in order):

1. **Verify environment variables:**
   ```bash
   ~/setup/verify-env.sh
   ```
   Should show your CONTAINER_HOSTNAME, not a random ID.

2. **Change default password:**
   ```bash
   ~/setup/change-password.sh
   ```

3. **Generate SSH keys:**
   ```bash
   ~/setup/generate-ssh-keys.sh
   ```

4. **Optional - Install Claude CLI:**
   ```bash
   setup-claude
   ```

---

## Network Requirements

A **macvlan network** named `dev-macvlan` must exist before deployment:

```bash
docker network create -d macvlan \
  --subnet=192.168.111.0/24 \
  --gateway=192.168.111.1 \
  --ip-range=192.168.111.200/29 \
  -o parent=eth0 \
  dev-macvlan
```

Adjust for your network configuration.

---

## Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| Random hostname | Use `CONTAINER_HOSTNAME` not `HOSTNAME` |
| New scripts missing | `docker builder prune -a -f` on host |
| Can't SSH | Check `docker ps`, verify SSH service running |
| Env vars not applied | Set manually in Portainer UI, not via env file |
| Build fails | Check Portainer build logs for errors |

---

## Documentation Quick Links

- **Quick Start:** [QUICKSTART.md](QUICKSTART.md)
- **Portainer Guide:** [PORTAINER_DEPLOY.md](PORTAINER_DEPLOY.md)
- **SSH Setup:** [SSH_SETUP_GUIDE.md](SSH_SETUP_GUIDE.md)
- **Hostname Issue:** [PORTAINER_HOSTNAME_RESERVED.md](PORTAINER_HOSTNAME_RESERVED.md)
- **Full Summary:** [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)

---

**Last Updated:** 2026-04-27

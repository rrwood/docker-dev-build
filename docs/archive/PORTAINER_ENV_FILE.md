# Using Environment Files with Portainer

## The Problem You're Experiencing

When Portainer deploys from **Git Repository**, it clones the repo to get `docker-compose.yml`. If you specify an env file like `env.rw.home`, Portainer looks for it **in the cloned repository**.

**But if that file is gitignored, it won't be in the repo!**

## Your Situation

```
Your local machine:
  ✓ env.rw.home exists with HOSTNAME=docker-dev
  ✓ File has correct settings

GitHub repository:
  ✗ env.rw.home is GITIGNORED (.gitignore blocks env.*)
  ✗ File doesn't exist in the repo

Portainer:
  ✗ Clones repo from GitHub
  ✗ Looks for env.rw.home
  ✗ File not found → uses defaults
  ✗ Result: random hostname
```

## Solutions

### Solution 1: Use the Committed `portainer.env` File (Recommended)

I've created a file that's **committed to the repository** and **not gitignored**.

**In Portainer:**

1. **When creating/editing stack:**
   - Build method: Git Repository
   - Repository URL: `https://github.com/rrwood/docker-dev-build`
   - Reference: `refs/heads/main`
   
2. **In "Environment variables" section:**
   - Click: **Load variables from .env file**
   - File path: `portainer.env`

3. **Deploy**

This will use the default settings from the committed file.

**To customize:**

You can override any variable by adding it in Portainer's environment variables section:

```
HOSTNAME=my-custom-hostname    ← This overrides portainer.env
USERNAME=rwood                 ← This overrides portainer.env
```

---

### Solution 2: Copy Your Settings and Set Manually (Most Control)

Since your `env.rw.home` has custom settings (like `USERNAME=rwood`), you should set these in Portainer UI:

1. **When creating stack in Portainer:**
   
2. **Click "+ add an environment variable" for each:**

   | Name | Value | Source |
   |------|-------|--------|
   | `USERNAME` | `rwood` | From your env.rw.home |
   | `USER_PASSWORD` | `m3bas303` | From your env.rw.home |
   | `CONTAINER_NAME` | `docker-dev` | From your env.rw.home |
   | `HOSTNAME` | `docker-dev` | From your env.rw.home |
   | `CONTAINER_IP` | `192.168.111.15` | From your env.rw.home |
   | `WORKSPACE_PATH` | `./workspace` | From your env.rw.home |
   | `TIMEZONE` | `UTC` | From your env.rw.home |

3. **Deploy**

---

### Solution 3: Commit Your Custom Env File (If You Want)

If you want to commit your custom settings:

**Option A: Use a different filename**

```bash
# Rename to a non-gitignored name
cp env.rw.home portainer.rw.env

# Edit .gitignore to allow it
# (I'll do this for you)

# Commit it
git add portainer.rw.env
git commit -m "Add custom portainer env file"
git push
```

Then in Portainer, specify: `portainer.rw.env`

**⚠️ WARNING:** This will commit your password to GitHub! Only do this if:
- Repository is private
- You're OK with password in git history
- Or you change the password after deployment

---

## How to Verify It's Working

After deploying, SSH into the container and run:

```bash
# New diagnostic script
~/setup/verify-env.sh
```

This will show:
- ✅ What hostname was set during build
- ✅ What hostname is at runtime
- ✅ If they match
- ✅ If your env vars were applied
- ❌ If there's a problem and how to fix it

---

## What File to Use in Portainer

| File | Committed? | Gitignored? | Use in Portainer? |
|------|------------|-------------|-------------------|
| `.env.example` | ✅ Yes | ❌ No | ⚠️ Has example values only |
| `portainer.env` | ✅ Yes | ❌ No | ✅ **Recommended - safe defaults** |
| `env.rw.home` | ❌ No | ✅ Yes | ❌ **Won't work - gitignored** |
| Custom `portainer.*.env` | Your choice | No | ✅ If you commit it |

---

## Current Best Practice

**Do this now:**

1. **Stop your current stack** (it's using wrong settings anyway)

2. **Create new stack:**
   - Name: `docker-dev`
   - Build: Git Repository
   - URL: `https://github.com/rrwood/docker-dev-build`
   - Ref: `refs/heads/main`

3. **Add your environment variables manually:**
   
   Copy these from your `env.rw.home` file:
   ```
   USERNAME=rwood
   USER_PASSWORD=m3bas303
   CONTAINER_NAME=docker-dev
   HOSTNAME=docker-dev
   CONTAINER_IP=192.168.111.15
   WORKSPACE_PATH=./workspace
   TIMEZONE=UTC
   ```

4. **Deploy**

5. **Verify:**
   ```bash
   ssh rwood@192.168.111.15
   ~/setup/verify-env.sh
   # Should show: hostname is docker-dev
   ```

---

## Why Manual Entry is Better Than Env File

**Advantages of setting vars in Portainer UI:**

1. ✅ **Always works** - not dependent on files in repo
2. ✅ **No secrets in git** - password stays in Portainer only
3. ✅ **Easy to update** - change in UI, redeploy
4. ✅ **Visible** - you can see what's set
5. ✅ **Portable** - different Portainer instances can have different settings

**Disadvantages of env file method:**

1. ❌ File must be in repo (can't be gitignored)
2. ❌ Harder to verify what's actually being used
3. ❌ Can't easily have different settings per environment
4. ❌ Password in git history (if committed)

---

## Summary

**Your problem:**
- `env.rw.home` is gitignored
- Not in GitHub repo
- Portainer can't find it
- Falls back to defaults
- Random hostname

**The fix:**
- Set variables **manually in Portainer UI**
- Or use committed `portainer.env` and override what you need
- Redeploy
- Run `~/setup/verify-env.sh` to confirm

---

**Next:** I'll push these changes to GitHub, then you can redeploy with manual env vars! 🚀

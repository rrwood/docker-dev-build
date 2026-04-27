# Setup Folder Feature

## Overview

All containers now include a `~/setup/` directory with helper scripts for post-deployment configuration.

## What's Included

### Location
```
/home/USERNAME/setup/
```

### Scripts

| Script | Purpose |
|--------|---------|
| `change-password.sh` | Change user password interactively |
| `generate-ssh-keys.sh` | Generate SSH keys for password-less access |
| `container-info.sh` | Display container information (user, network, tools, etc.) |
| `welcome-motd.sh` | Welcome message (auto-runs on login) |

### Documentation

| File | Content |
|------|---------|
| `README.md` | Complete post-deployment setup guide |
| `HELPER_SCRIPTS.md` | Detailed documentation for each script |

## First Login Experience

When users log in for the first time, they see:

```
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║       Welcome to Your Development Container! 🚀               ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝

📋 First Time Setup - Important!

   🔐 1. Change your default password:
      cd ~/setup && ./change-password.sh

   🔑 2. Generate SSH keys (recommended):
      cd ~/setup && ./generate-ssh-keys.sh

   📖 3. Read the setup guide:
      cat ~/setup/README.md
```

## Recommended Workflow

**Step 1: SSH into container**
```bash
ssh devuser@192.168.111.15
```

**Step 2: Change password**
```bash
cd ~/setup
./change-password.sh
```

**Step 3: Generate SSH keys**
```bash
./generate-ssh-keys.sh
```

**Step 4: View container info**
```bash
./container-info.sh
```

**Step 5: Install tools as needed**
```bash
setup-claude      # Install Claude CLI
setup-litellm     # Install LiteLLM
install-ngrok     # Install ngrok
```

## How It Works

### Build Process

1. **Dockerfile clones repository** from GitHub
2. **Setup scripts are copied** from `setup/` directory to `/tmp/user-setup`
3. **User is created** with configured USERNAME
4. **Scripts are copied** to `/home/${USERNAME}/setup/`
5. **Welcome message is installed** to `/etc/profile.d/welcome.sh`
6. **Permissions are set** (scripts executable, owned by user)

### Welcome Message

The welcome message is triggered by `/etc/profile.d/welcome.sh` which sources `welcome-motd.sh`.

Shows on every login until user completes setup (can be disabled by removing `.first_login` file).

## Environment Variables

Enhanced `.env` configuration with better documentation:

```env
# USERNAME - The user account created in the container
USERNAME=devuser

# USER_PASSWORD - Initial password (CHANGE AFTER DEPLOYMENT!)
USER_PASSWORD=changeme123

# HOSTNAME - Container hostname (shown in shell prompt)
HOSTNAME=docker-dev
```

## Security Features

### Password Change Script
- Validates current password
- Requires password confirmation
- Shows password strength tips
- Updates user password securely

### SSH Key Generator
- Creates 4096-bit RSA keys
- Backups existing keys automatically
- Displays public key for easy copying
- Optionally adds to authorized_keys
- Sets correct permissions (700/.ssh, 600/keys)

## Benefits

✅ **User-friendly** - Clear instructions on first login  
✅ **Secure** - Encourages password change and SSH key setup  
✅ **Self-documenting** - Complete guides in ~/setup/  
✅ **Automated** - Scripts handle complex tasks  
✅ **Consistent** - Same setup process for all deployments  
✅ **Maintainable** - Scripts pulled from GitHub, easy to update  

## Developer Notes

### Adding New Scripts

1. Create script in `setup/` directory
2. Make executable: `chmod +x setup/new-script.sh`
3. Update `setup/README.md` to document it
4. Update `setup/HELPER_SCRIPTS.md` with details
5. Commit and push to GitHub
6. Rebuild container to include new script

### Modifying Welcome Message

Edit `setup/welcome-motd.sh` to customize the welcome banner.

### Disabling Welcome Message

To disable for a specific user:
```bash
rm ~/.first_login
```

To disable system-wide:
```bash
sudo rm /etc/profile.d/welcome.sh
```

## Testing

Test the scripts in a local build:

```bash
# Build container
docker-compose build

# Start container
docker-compose up -d

# Access container
docker exec -it docker-dev su - devuser

# Test scripts
cd ~/setup
./container-info.sh
./generate-ssh-keys.sh
./change-password.sh
```

## Troubleshooting

### Scripts not found

**Issue:** `~/setup/` directory is empty or doesn't exist

**Solution:**
```bash
# Check if scripts were copied during build
ls -la ~/setup/

# If missing, check build logs
docker logs docker-dev

# Rebuild container
# In Portainer: Pull and redeploy
```

### Scripts not executable

**Issue:** Permission denied when running scripts

**Solution:**
```bash
chmod +x ~/setup/*.sh
```

### Welcome message not showing

**Issue:** No welcome message on login

**Solution:**
```bash
# Check if profile script exists
ls -la /etc/profile.d/welcome.sh

# Test manually
bash /etc/profile.d/welcome.sh
```

---

**This feature is automatically included in all container builds from the repository.**

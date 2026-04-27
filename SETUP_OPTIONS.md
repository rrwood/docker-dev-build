# Setup Options - Choose Your Workflow

This project supports multiple setup workflows depending on your platform and deployment method.

## Quick Decision Guide

```
┌─────────────────────────────────────────────────────┐
│         What's your deployment method?              │
└─────────────────────────────────────────────────────┘
                        │
        ┌───────────────┴───────────────┐
        │                               │
    Portainer                   Docker Compose CLI
        │                               │
        ▼                               ▼
┌───────────────────┐          ┌────────────────┐
│  Windows?         │          │  Windows?      │
│  ✅ setup.ps1     │          │  ✅ setup.sh   │
│                   │          │  (via WSL/Git) │
│  Linux/Mac?       │          │                │
│  ✅ setup.sh      │          │  Linux/Mac?    │
│  (generate only)  │          │  ✅ setup.sh   │
└───────────────────┘          └────────────────┘
```

---

## Option 1: Pure PowerShell (Windows - No Dependencies) ⭐ RECOMMENDED FOR WINDOWS

**Best for:** Windows users deploying to Portainer

### What you need:
- ✅ Windows PowerShell 5.1+ (built into Windows)
- ✅ Nothing else! (OpenSSH optional for SSH key generation)

### How to run:
```batch
setup-powershell.bat
```

or directly:
```powershell
.\setup.ps1
```

### What it does:
1. ✅ Interactive configuration prompts
2. ✅ Generates `Dockerfile`
3. ✅ Generates `docker-compose.yml`
4. ✅ (Optional) Generates SSH keys using Windows OpenSSH
5. ✅ (Optional) Updates `~/.ssh/config`
6. ✅ Creates `copy-ssh-keys.ps1` script
7. ✅ Creates `PORTAINER_DEPLOYMENT.md` guide
8. ❌ Does NOT build/start container (you do this in Portainer)

### Next steps:
1. Open Portainer UI
2. Create new Stack using generated `docker-compose.yml`
3. Or build image and deploy manually
4. Run `.\copy-ssh-keys.ps1` after container starts

### Documentation:
- **[PORTAINER_QUICK_START.md](PORTAINER_QUICK_START.md)** - Quick guide
- **PORTAINER_DEPLOYMENT.md** - Generated detailed guide

---

## Option 2: Bash Script with Auto-Build (Linux/Mac/WSL)

**Best for:** Linux, Mac, or WSL users who want automatic build

### What you need:
- ✅ Bash shell
- ✅ Docker and Docker Compose installed
- ✅ ssh-keygen (usually pre-installed)

### How to run:
```bash
./setup.sh
```

### What it does:
1. ✅ Interactive configuration prompts
2. ✅ Generates `Dockerfile`
3. ✅ Generates `docker-compose.yml`
4. ✅ (Optional) Generates SSH keys
5. ✅ (Optional) Updates `~/.ssh/config`
6. ✅ Creates `copy-ssh-keys.sh` script
7. ✅ **Builds container image**
8. ✅ **Starts container**
9. ✅ **Copies SSH keys to container**
10. ✅ **Tests SSH connection**

### Next steps:
- SSH into container: `ssh <hostname>`
- Container is already running!

### Documentation:
- **[QUICKSTART.md](QUICKSTART.md)** - Full quick start guide

---

## Option 3: Bash Script on Windows (via Git Bash or WSL)

**Best for:** Windows users who already have Git Bash or WSL

### What you need:
- ✅ Git Bash or WSL installed
- ✅ Docker Desktop or Docker in WSL
- ✅ ssh-keygen (included with Git Bash/WSL)

### How to run:
```batch
setup.bat
```

This runs `setup.sh` through Git Bash or WSL.

### What it does:
Same as Option 2 - full auto-build and deployment.

### Next steps:
- SSH into container: `ssh <hostname>`
- Container is already running!

### Documentation:
- **[QUICKSTART.md](QUICKSTART.md)** - Full quick start guide

---

## Option 4: Manual Configuration

**Best for:** Users who want full control or have custom requirements

### What you need:
- ✅ Text editor
- ✅ Understanding of Docker and docker-compose

### How to do it:
1. Edit `Dockerfile` manually
2. Edit `docker-compose.yml` manually
3. Build: `docker build -t myimage .`
4. Deploy via Portainer or Docker Compose

### Documentation:
- **[README.md](README.md)** - Full manual configuration guide

---

## Comparison Table

| Feature | PowerShell<br>`setup.ps1` | Bash<br>`setup.sh` | Manual |
|---------|---------------------------|-------------------|--------|
| **Windows Native** | ✅ Yes | ❌ Needs WSL/Git Bash | ✅ Yes |
| **No Dependencies** | ✅ Just PowerShell | ❌ Needs Bash | ✅ Just text editor |
| **Interactive Config** | ✅ Yes | ✅ Yes | ❌ Manual |
| **Generates Dockerfile** | ✅ Yes | ✅ Yes | ❌ You edit it |
| **Generates docker-compose.yml** | ✅ Yes | ✅ Yes | ❌ You edit it |
| **SSH Key Generation** | ✅ Optional | ✅ Optional | ❌ Manual |
| **Auto Build Image** | ❌ No | ✅ Yes | ❌ Manual |
| **Auto Start Container** | ❌ No | ✅ Yes | ❌ Manual |
| **Copy SSH Keys** | ⚠️ Script only | ✅ Automatic | ❌ Manual |
| **Test Connection** | ❌ No | ✅ Yes | ❌ Manual |
| **Best For** | Portainer | Docker Compose | Custom setups |

---

## Detailed Workflow Diagrams

### PowerShell Workflow (Portainer Deployment)

```
You run setup.ps1
        │
        ▼
Interactive prompts (user, password, components, SSH)
        │
        ▼
Generates:
  • Dockerfile
  • docker-compose.yml
  • SSH keys (optional)
  • copy-ssh-keys.ps1
  • PORTAINER_DEPLOYMENT.md
        │
        ▼
You open Portainer UI
        │
        ▼
Create Stack with docker-compose.yml
        │
        ▼
Portainer builds and starts container
        │
        ▼
You run: .\copy-ssh-keys.ps1
        │
        ▼
SSH into container: ssh <hostname>
        │
        ▼
✅ Done!
```

### Bash Workflow (Auto-Deploy)

```
You run setup.sh
        │
        ▼
Interactive prompts (user, password, components, SSH)
        │
        ▼
Generates:
  • Dockerfile
  • docker-compose.yml
  • SSH keys (optional)
  • copy-ssh-keys.sh
        │
        ▼
Auto-builds container image
        │
        ▼
Auto-starts container
        │
        ▼
Auto-copies SSH keys
        │
        ▼
Auto-tests SSH connection
        │
        ▼
SSH into container: ssh <hostname>
        │
        ▼
✅ Done!
```

---

## Which Setup Should You Choose?

### Choose **PowerShell** (`setup.ps1`) if:
- ✅ You're on Windows
- ✅ You use Portainer for container management
- ✅ You don't want to install WSL or Git Bash
- ✅ You want to review files before building
- ✅ You want to manually control the build process

### Choose **Bash** (`setup.sh`) if:
- ✅ You're on Linux or Mac
- ✅ You have WSL or Git Bash on Windows
- ✅ You want fully automated setup
- ✅ You use Docker Compose CLI
- ✅ You want the script to build and start everything

### Choose **Manual** if:
- ✅ You have specific custom requirements
- ✅ You want to learn Docker configuration
- ✅ You need to integrate with existing infrastructure
- ✅ You want complete control over every detail

---

## Common Questions

### Q: Can I use PowerShell script with Docker Compose instead of Portainer?

**A:** Yes! The `setup.ps1` script generates standard `docker-compose.yml`. After running the script:

```powershell
# Build and start with Docker Compose
docker-compose up -d

# Copy SSH keys
.\copy-ssh-keys.ps1
```

### Q: Can I use Bash script to generate files for Portainer?

**A:** Yes! When `setup.sh` asks "Build and start the container now?", answer **No**. This will generate files only, similar to the PowerShell workflow.

### Q: I ran setup.ps1 but want to rebuild with different settings

**A:** Just run it again! It will regenerate all files with new settings. Old SSH keys can be optionally kept or overwritten.

### Q: Can I switch between PowerShell and Bash workflows?

**A:** Yes! Both generate the same `Dockerfile` and `docker-compose.yml`. You can use either script, or even edit the files manually after generation.

### Q: What if I don't have OpenSSH on Windows?

**A:** The PowerShell script will still work - it will just skip SSH key generation. You can:
- Install OpenSSH: `Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0`
- Or use password authentication instead of keys
- Or generate keys manually later

---

## After Setup: Inside the Container

Regardless of which setup method you used, once inside the container you can:

```bash
# Install Claude CLI (if not auto-installed)
setup-claude

# Install ngrok (if not auto-installed)
install-ngrok

# Setup Claude Code with Gemini (free alternative to Anthropic API)
setup-litellm

# Add your Google API key
nano ~/.config/litellm/.env

# Start LiteLLM proxy
~/.config/litellm/start-litellm.sh

# In another terminal: export environment and run Claude
source ~/.config/litellm/export-claude-env.sh
claude
```

---

## Need Help?

- **Quick Start**: [QUICKSTART.md](QUICKSTART.md)
- **Portainer Guide**: [PORTAINER_QUICK_START.md](PORTAINER_QUICK_START.md)
- **Full Documentation**: [README.md](README.md)
- **Project Structure**: [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)
- **Helper Scripts**: [scripts/README.md](scripts/README.md)

---

**Choose your workflow and get started! 🚀**

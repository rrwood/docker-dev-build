# Project Rebuild - Portainer-Focused Deployment

## Summary of Changes

This project has been rebuilt to eliminate manual setup scripts and streamline deployment through Portainer with GitHub integration.

## What Changed

### ✅ Dockerfile - GitHub Integration
- **Now pulls setup scripts from GitHub during build**
- Uses `ARG` directives for customizable builds
- Clones repository, copies scripts, then cleans up
- Scripts always fresh from GitHub - no manual syncing needed

### ✅ docker-compose.yml - Environment Variable Support
- All configuration via environment variables
- Works seamlessly with Portainer stacks
- Supports `.env` file for local deployments
- No hardcoded values

### ✅ New Files Created

#### PORTAINER_DEPLOY.md
Complete Portainer deployment guide with:
- Step-by-step stack creation
- Environment variable reference
- Network setup instructions
- Troubleshooting section

#### .env.example
Template for environment variables:
- Container configuration (username, password, IP)
- Optional components (Claude CLI, ngrok)
- GitHub repository settings
- Workspace and timezone

#### CHANGES.md (this file)
Documentation of the rebuild process

### ✅ Updated Files

#### README.md
- Focused on Portainer deployment as primary method
- Removed references to manual setup scripts
- Updated documentation structure
- Added "How It Works" section explaining GitHub pull

#### QUICKSTART.md
- Rewritten for Portainer-first approach
- Simplified deployment steps
- Removed old script-based setup
- Focus on environment variable configuration

#### .gitignore
- Added old setup scripts to ignore list
- Prevents accidentally committing deprecated scripts

## What Was Deprecated

### Old Setup Scripts (No Longer Needed)
- `setup.sh` - Bash setup script
- `setup.ps1` - PowerShell setup script
- `setup.bat` - Windows batch wrapper
- `setup-powershell.bat` - PowerShell wrapper
- `verify-setup.sh` - Setup verification

**These scripts are now obsolete** - all setup happens during Docker build via Portainer.

### Old Documentation (Superseded)
- `START_HERE.md` - Old entry point
- `SETUP_OPTIONS.md` - Old setup methods comparison
- `PORTAINER_QUICK_START.md` - Old Portainer guide

**New entry points:**
- `README.md` - Main documentation
- `QUICKSTART.md` - Quick deployment guide
- `PORTAINER_DEPLOY.md` - Detailed Portainer guide

## How It Works Now

### Build Process

1. **Portainer reads docker-compose.yml from GitHub**
2. **Docker build process:**
   - Clones GitHub repository to `/tmp/setup-repo`
   - Copies setup scripts from `scripts/` directory
   - Installs optional components based on build args
   - Cleans up cloned repository
3. **Scripts available in `/usr/local/bin/`**
   - `install-ngrok`
   - `setup-litellm`
   - `setup-claude`

### Configuration Flow

```
Portainer UI Environment Variables
         ↓
   docker-compose.yml
         ↓
     Dockerfile ARGs
         ↓
   Container Build
         ↓
Scripts Pulled from GitHub
         ↓
   Running Container
```

## Benefits of New Approach

### ✅ No Manual Setup Required
- No need to run scripts on host machine
- Everything automated during build

### ✅ Always Up-to-Date
- Scripts pulled fresh from GitHub each build
- No version sync issues

### ✅ Portainer-Optimized
- Deploy directly from GitHub repo
- All config via environment variables
- Easy updates: Pull and redeploy

### ✅ Cleaner Repository
- No generated files in git
- Deprecated scripts ignored
- Clear separation of config and code

### ✅ Flexible Deployment
- Works with Portainer (recommended)
- Works with docker-compose manually
- Customizable via `.env` file

## Migration Guide

### If You Were Using Old Setup Scripts

**Old Way:**
```bash
./setup.sh
# Interactive prompts...
# Generates Dockerfile and docker-compose.yml
# Builds container
```

**New Way (Portainer):**
1. Create stack in Portainer
2. Point to GitHub repo
3. Set environment variables
4. Deploy

**New Way (Manual):**
```bash
git clone https://github.com/rrwood/docker-dev-build.git
cd docker-dev-build
cp .env.example .env
nano .env  # Configure
docker-compose up -d
```

### If You Have Existing Containers

1. **Export your current configuration** (username, password, IP)
2. **Stop and remove old container**
3. **Deploy new version** via Portainer with your config
4. **Your workspace data is preserved** if using volume mounts

## Testing Checklist

Before pushing to production:

- [ ] Portainer can clone repository
- [ ] Build completes successfully
- [ ] Scripts are available in container (`which install-ngrok`)
- [ ] SSH access works
- [ ] Environment variables are applied correctly
- [ ] Optional components install correctly (Claude, ngrok)
- [ ] LiteLLM setup works
- [ ] Workspace volume mounts correctly

## Next Steps

1. **Test Portainer deployment**
   - Create stack from GitHub
   - Verify all scripts work
   
2. **Update documentation if needed**
   - Add any missing troubleshooting
   - Update network examples for your environment

3. **Push to GitHub**
   ```bash
   git add .
   git commit -m "Rebuild: Portainer-focused deployment with GitHub integration"
   git push origin main
   ```

4. **Test pull and redeploy**
   - Make a small change
   - Push to GitHub
   - Use Portainer's "Pull and redeploy" feature

## Configuration Reference

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `USERNAME` | `devuser` | Container user |
| `USER_PASSWORD` | `changeme123` | User password |
| `CONTAINER_NAME` | `docker-dev` | Container name |
| `HOSTNAME` | `docker-dev` | Container hostname |
| `CONTAINER_IP` | `192.168.111.15` | Container IP address |
| `INSTALL_NGROK` | `false` | Install ngrok during build |
| `NGROK_AUTH_TOKEN` | _(empty)_ | ngrok auth token |
| `WORKSPACE_PATH` | `./workspace` | Host workspace path |
| `TIMEZONE` | `UTC` | Container timezone |
| `GITHUB_REPO` | _(repo url)_ | GitHub repository |
| `GITHUB_BRANCH` | `main` | GitHub branch |

### Available Helper Scripts

After container is built, these scripts are available:

- **`setup-litellm`** - Setup LiteLLM proxy for Claude Code + Gemini
- **`install-ngrok [token]`** - Install ngrok
- **`setup-claude`** - Install Claude CLI

## Troubleshooting

### Build fails with "fatal: could not read Username"

**Issue:** Git authentication required  
**Solution:** Repository must be public, or use deploy keys

### Scripts not found in container

**Issue:** `/usr/local/bin/setup-litellm: not found`  
**Solution:** Check build logs - GitHub clone may have failed

### Environment variables not applied

**Issue:** Default values used instead of custom values  
**Solution:** Check environment variable names match exactly (case-sensitive)

## Support

For issues or questions:
1. Check **[PORTAINER_DEPLOY.md](PORTAINER_DEPLOY.md)** troubleshooting section
2. Review build logs in Portainer
3. Check Docker logs: `docker logs docker-dev`
4. Verify network configuration

---

**Project Status:** ✅ Rebuilt and ready for Portainer deployment

**Last Updated:** 2026-04-27

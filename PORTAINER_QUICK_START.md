# Portainer Quick Start Guide

Deploy your development container to Portainer in 5 minutes!

## Step 1: Generate Configuration Files

Run the PowerShell setup script (no dependencies required):

```batch
setup-powershell.bat
```

Or run PowerShell directly:

```powershell
.\setup.ps1
```

Follow the prompts to configure:
- Username and password
- Container hostname and IP
- Optional components (Claude CLI, ngrok)
- SSH key generation

This will create:
- ✅ `Dockerfile`
- ✅ `docker-compose.yml`
- ✅ `copy-ssh-keys.ps1` (if SSH keys configured)
- ✅ `PORTAINER_DEPLOYMENT.md` (detailed guide)

## Step 2: Deploy in Portainer

### Method A: Using Stacks (Easiest)

1. **Open Portainer** (usually `http://localhost:9000` or `http://your-server:9000`)

2. **Go to Stacks**
   - Click "Stacks" in left sidebar
   - Click "+ Add stack"

3. **Upload docker-compose.yml**
   - Name: Enter your container hostname (e.g., `docker-dev`)
   - Build method: Choose "Upload"
   - Click "Upload" and select your `docker-compose.yml`

4. **Deploy**
   - Click "Deploy the stack"
   - Wait for build to complete

5. **Copy SSH Keys** (if configured)
   ```powershell
   .\copy-ssh-keys.ps1
   ```

### Method B: Build Image First, Then Deploy

1. **Build the Docker image**
   ```powershell
   docker build -t docker-dev:latest .
   ```

2. **Open Portainer**

3. **Go to Containers**
   - Click "Containers"
   - Click "+ Add container"

4. **Configure Container**
   - **Name**: `docker-dev` (your hostname)
   - **Image**: `docker-dev:latest`
   - **Network tab**:
     - Network: Select your network (e.g., `dev-macvlan`)
     - IPv4 Address: Enter your IP (e.g., `192.168.111.15`)
   - **Volumes tab**:
     - map container: `/app`
     - map to host: `C:\path\to\devserverdocker\workspace`
   - **Restart policy tab**:
     - Select "Unless stopped"
   - **Capabilities tab**:
     - Add capability: `NET_ADMIN`

5. **Deploy Container**
   - Click "Deploy the container"

6. **Copy SSH Keys** (if configured)
   ```powershell
   .\copy-ssh-keys.ps1
   ```

## Step 3: Connect to Your Container

### If you configured SSH keys:
```powershell
ssh docker-dev
```

### Or connect directly:
```powershell
ssh devuser@192.168.111.15
```
(Use your configured username and IP)

## Step 4: Setup Claude Code with Gemini (Optional)

Inside the container:

```bash
# Setup LiteLLM for free Claude Code
setup-litellm

# Add your Google API key
nano ~/.config/litellm/.env
# Get key from: https://aistudio.google.com/app/apikey

# Start LiteLLM proxy (in one terminal)
~/.config/litellm/start-litellm.sh

# In another terminal, export environment variables
source ~/.config/litellm/export-claude-env.sh

# Run Claude Code
claude
```

## Troubleshooting

### Container won't start in Portainer

**Check logs:**
- In Portainer, click on the container
- Click "Logs" tab
- Look for error messages

**Common issues:**

1. **Network doesn't exist**
   ```powershell
   docker network create -d macvlan `
     --subnet=192.168.111.0/24 `
     --gateway=192.168.111.1 `
     -o parent=eth0 `
     dev-macvlan
   ```

2. **Volume path doesn't exist**
   - Make sure `workspace` directory exists
   - Or create it: `mkdir workspace`

3. **IP address conflict**
   - Change IP in docker-compose.yml
   - Or in Portainer container settings

### Can't SSH to container

1. **Check container is running**
   - In Portainer, verify status is "running" (green)

2. **Check SSH service**
   ```powershell
   docker exec docker-dev rc-service sshd status
   ```

3. **Test network connectivity**
   ```powershell
   ping 192.168.111.15
   ```

4. **Try password authentication**
   ```powershell
   ssh -o PreferredAuthentications=password devuser@192.168.111.15
   ```

5. **Re-copy SSH keys**
   ```powershell
   .\copy-ssh-keys.ps1
   ```

### SSH keys not working

1. **Verify keys copied to container**
   ```powershell
   docker exec docker-dev ls -la /home/devuser/.ssh/
   ```

2. **Check key permissions**
   - Should show `authorized_keys` with correct permissions

3. **Manual copy**
   ```powershell
   # Copy public key
   type $env:USERPROFILE\.ssh\docker-dev-container.pub | `
     docker exec -i docker-dev tee /home/devuser/.ssh/authorized_keys

   # Fix permissions
   docker exec docker-dev chown devuser:devuser /home/devuser/.ssh/authorized_keys
   docker exec docker-dev chmod 600 /home/devuser/.ssh/authorized_keys
   ```

## Quick Commands Reference

### PowerShell (on host machine)

```powershell
# Generate configuration
.\setup.ps1

# Build image
docker build -t docker-dev:latest .

# Copy SSH keys to running container
.\copy-ssh-keys.ps1

# Connect via SSH
ssh docker-dev

# View container logs
docker logs docker-dev

# Stop container
docker stop docker-dev

# Start container
docker start docker-dev

# Remove container (careful!)
docker rm -f docker-dev
```

### Inside Container

```bash
# Install Claude CLI (if not auto-installed)
setup-claude

# Install ngrok (if not auto-installed)
install-ngrok

# Setup Claude Code + Gemini integration
setup-litellm

# Start LiteLLM proxy
~/.config/litellm/start-litellm.sh

# Export Claude environment
source ~/.config/litellm/export-claude-env.sh

# Run Claude Code
claude

# Change password
passwd

# View SSH keys
ls -la ~/.ssh/
```

## Network Configuration Notes

If using **macvlan network**, you may need to adjust settings:

1. **Find your network interface**
   ```powershell
   ipconfig
   ```
   Look for your active network adapter

2. **Update docker-compose.yml**
   ```yaml
   driver_opts:
     parent: eth0  # Change to your interface (e.g., "Ethernet", "Wi-Fi")
   ```

3. **Update subnet/gateway** to match your network:
   ```yaml
   ipam:
     config:
       - subnet: 192.168.1.0/24      # Your network subnet
         gateway: 192.168.1.1         # Your gateway
         ip_range: 192.168.1.200/29   # IP range for containers
   ```

## Additional Resources

- **Full Documentation**: [README.md](README.md)
- **Detailed Portainer Guide**: [PORTAINER_DEPLOYMENT.md](PORTAINER_DEPLOYMENT.md)
- **Project Structure**: [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)
- **Scripts Documentation**: [scripts/README.md](scripts/README.md)

## Getting Help

If you run into issues:

1. Check **PORTAINER_DEPLOYMENT.md** for detailed troubleshooting
2. Review container logs in Portainer
3. Verify network configuration matches your environment
4. Test basic connectivity (`ping`, `docker exec`)

---

**Happy containerizing! 🐳**

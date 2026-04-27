# Docker Development Container Setup Script (PowerShell)
# Pure PowerShell - no WSL or external dependencies required
# Generates Dockerfile and docker-compose.yml for manual Portainer deployment

#Requires -Version 5.1

# Color output functions
function Write-Header {
    param([string]$Message)
    Write-Host "`n======================================" -ForegroundColor Blue
    Write-Host $Message -ForegroundColor Blue
    Write-Host "======================================`n" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

# Prompt for yes/no
function Get-YesNo {
    param(
        [string]$Prompt,
        [bool]$Default = $true
    )

    $defaultText = if ($Default) { "[Y/n]" } else { "[y/N]" }
    $response = Read-Host "$Prompt $defaultText"

    if ([string]::IsNullOrWhiteSpace($response)) {
        return $Default
    }

    return $response -match '^[Yy]'
}

# Prompt for input with default
function Get-Input {
    param(
        [string]$Prompt,
        [string]$Default = ""
    )

    if ($Default) {
        $response = Read-Host "$Prompt [$Default]"
        if ([string]::IsNullOrWhiteSpace($response)) {
            return $Default
        }
        return $response
    }

    return Read-Host $Prompt
}

# Prompt for password (secure)
function Get-Password {
    param([string]$Prompt)

    while ($true) {
        $password = Read-Host "$Prompt" -AsSecureString
        $passwordConfirm = Read-Host "Confirm password" -AsSecureString

        # Convert to plain text for comparison
        $pwd1 = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
        )
        $pwd2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordConfirm)
        )

        if ([string]::IsNullOrWhiteSpace($pwd1)) {
            Write-Error "Password cannot be empty"
            continue
        }

        if ($pwd1 -eq $pwd2) {
            return $pwd1
        }

        Write-Error "Passwords do not match, please try again"
    }
}

# Main script
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DockerfilePath = Join-Path $ScriptDir "Dockerfile"
$ComposePath = Join-Path $ScriptDir "docker-compose.yml"

Write-Header "Docker Development Container Setup (PowerShell)"

Write-Host "This script will generate Dockerfile and docker-compose.yml for Portainer deployment."
Write-Host ""

# Read current values from docker-compose.yml if it exists
$CurrentIP = "192.168.111.15"
$CurrentHostname = "docker-dev"
$CurrentNetworkName = "dev-macvlan"
$IsNetworkExternal = $false

if (Test-Path $ComposePath) {
    Write-Host "Found existing docker-compose.yml, reading current values..." -ForegroundColor Cyan
    $composeContent = Get-Content $ComposePath -Raw

    if ($composeContent -match 'ipv4_address:\s*(\S+)') {
        $CurrentIP = $Matches[1]
    }
    if ($composeContent -match 'hostname:\s*(\S+)') {
        $CurrentHostname = $Matches[1]
    }
    if ($composeContent -match 'networks:\s+(\S+):') {
        $CurrentNetworkName = $Matches[1]
    }
    if ($composeContent -match 'external:\s*true') {
        $IsNetworkExternal = $true
    }
}

# ============================================
# STEP 1: Basic Configuration
# ============================================
Write-Header "Step 1: Basic Configuration"

$ContainerUser = Get-Input "Enter username for container user" "devuser"
$ContainerPass = Get-Password "Enter password for $ContainerUser"
$ContainerHostname = Get-Input "Enter container hostname" $CurrentHostname
$ContainerIP = Get-Input "Enter container IP address" $CurrentIP

# ============================================
# STEP 2: Network Configuration
# ============================================
Write-Header "Step 2: Network Configuration"

$NetworkName = Get-Input "Enter Docker network name" $CurrentNetworkName
$NetworkExternal = Get-YesNo "Is this an external/existing network?" $IsNetworkExternal

if (-not $NetworkExternal) {
    Write-Host "You'll need to configure network subnet/gateway in docker-compose.yml manually" -ForegroundColor Yellow
}

# ============================================
# STEP 3: Optional Components
# ============================================
Write-Header "Step 3: Optional Components"

$InstallClaude = Get-YesNo "Install Claude CLI automatically?" $true
$InstallNgrok = Get-YesNo "Install ngrok automatically?" $false

if ($InstallNgrok) {
    $NgrokToken = Get-Input "Enter ngrok auth token (leave empty to skip)" ""
}

# ============================================
# STEP 4: SSH Configuration
# ============================================
Write-Header "Step 4: SSH Key Setup (Optional)"

$SetupSSH = Get-YesNo "Generate SSH key pair for this container?" $true
$SSHKeyName = "docker-dev-container"
$SSHKeyPath = Join-Path $env:USERPROFILE ".ssh\$SSHKeyName"

if ($SetupSSH) {
    Write-Host "`nSSH key will be created at: $SSHKeyPath" -ForegroundColor Cyan

    if (Test-Path $SSHKeyPath) {
        Write-Warning "SSH key already exists at $SSHKeyPath"
        $OverwriteKey = Get-YesNo "Overwrite existing key?" $false
        $GenerateKey = $OverwriteKey
    } else {
        $GenerateKey = $true
    }

    $UpdateSSHConfig = Get-YesNo "Update SSH config (~/.ssh/config)?" $true
}

# ============================================
# STEP 5: Summary
# ============================================
Write-Header "Configuration Summary"

Write-Host "Container Settings:"
Write-Host "  Hostname: $ContainerHostname"
Write-Host "  IP Address: $ContainerIP"
Write-Host "  Username: $ContainerUser"
Write-Host "  Password: $('*' * $ContainerPass.Length)"
Write-Host ""
Write-Host "Network Settings:"
Write-Host "  Network Name: $NetworkName"
Write-Host "  External Network: $NetworkExternal"
Write-Host ""
Write-Host "Optional Components:"
Write-Host "  Claude CLI: $(if ($InstallClaude) { 'Yes' } else { 'No' })"
Write-Host "  ngrok: $(if ($InstallNgrok) { 'Yes' } else { 'No' })"
Write-Host ""
Write-Host "SSH Configuration:"
Write-Host "  Generate SSH key: $(if ($SetupSSH) { 'Yes' } else { 'No' })"
if ($SetupSSH) {
    Write-Host "  SSH Key: $SSHKeyPath"
    Write-Host "  Update SSH config: $(if ($UpdateSSHConfig) { 'Yes' } else { 'No' })"
}
Write-Host ""

if (-not (Get-YesNo "Proceed with this configuration?" $true)) {
    Write-Error "Setup cancelled"
    exit 1
}

# ============================================
# STEP 6: Generate Dockerfile
# ============================================
Write-Header "Step 6: Generating Dockerfile"

$dockerfileContent = @"
FROM alpine:latest

# Install base packages
RUN apk add --no-cache \
    python3 \
    py3-pip \
    curl \
    bash \
    ca-certificates \
    wget \
    openssh \
    nano \
    vim \
    git \
    sudo \
    shadow

"@

# Add Claude CLI installation
if ($InstallClaude) {
    $dockerfileContent += @"

# Install Claude CLI
RUN curl -fsSL https://claude.ai/install.sh | sh

"@
    Write-Success "Added Claude CLI installation to Dockerfile"
} else {
    Write-Warning "Skipped Claude CLI installation (use setup-claude script in container)"
}

# Add ngrok installation
if ($InstallNgrok) {
    $dockerfileContent += @"

# Install ngrok
RUN wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz && \
    tar xvzf ngrok-v3-stable-linux-amd64.tgz && \
    mv ngrok /usr/local/bin/ && \
    rm ngrok-v3-stable-linux-amd64.tgz && \
    chmod +x /usr/local/bin/ngrok

"@

    if ($NgrokToken) {
        $dockerfileContent += @"

# Configure ngrok auth token
RUN ngrok config add-authtoken $NgrokToken

"@
        Write-Success "Added ngrok installation with auth token to Dockerfile"
    } else {
        Write-Success "Added ngrok installation to Dockerfile (no auth token)"
    }
} else {
    Write-Warning "Skipped ngrok installation (use install-ngrok script in container)"
}

# Add SSH configuration and user setup
$dockerfileContent += @"

# Setup SSH - disable root login, allow user login with password and keys
RUN ssh-keygen -A && \
    sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#AuthorizedKeysFile.*/AuthorizedKeysFile .ssh\/authorized_keys/' /etc/ssh/sshd_config

# Create user: $ContainerUser
RUN adduser -D -s /bin/bash $ContainerUser && \
    echo '${ContainerUser}:${ContainerPass}' | chpasswd && \
    mkdir -p /home/$ContainerUser/.ssh && \
    chmod 700 /home/$ContainerUser/.ssh && \
    chown -R ${ContainerUser}:${ContainerUser} /home/$ContainerUser/.ssh && \
    echo '$ContainerUser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$ContainerUser

# Copy helper scripts
COPY scripts/install-ngrok.sh /usr/local/bin/install-ngrok
COPY scripts/setup-litellm.sh /usr/local/bin/setup-litellm
COPY scripts/setup-claude.sh /usr/local/bin/setup-claude
RUN chmod +x /usr/local/bin/install-ngrok /usr/local/bin/setup-litellm /usr/local/bin/setup-claude

# Create working directory
WORKDIR /app
RUN chown ${ContainerUser}:${ContainerUser} /app

# Expose SSH port
EXPOSE 22

# Keep container running and start SSH
CMD ["/usr/sbin/sshd", "-D"]
"@

# Write Dockerfile
Set-Content -Path $DockerfilePath -Value $dockerfileContent -Encoding UTF8
Write-Success "Dockerfile generated at $DockerfilePath"

# ============================================
# STEP 7: Generate docker-compose.yml
# ============================================
Write-Header "Step 7: Generating docker-compose.yml"

$composeContent = @"
version: '3.8'

services:
  $ContainerHostname:
    build: .
    container_name: $ContainerHostname
    hostname: $ContainerHostname
    restart: unless-stopped
    networks:
      ${NetworkName}:
        ipv4_address: $ContainerIP
    volumes:
      - ./workspace:/app
    cap_add:
      - NET_ADMIN

networks:
  ${NetworkName}:
"@

if ($NetworkExternal) {
    $composeContent += @"

    external: true
"@
} else {
    $composeContent += @"

    driver: macvlan
    driver_opts:
      parent: eth0  # Change to your network interface
    ipam:
      config:
        - subnet: 192.168.111.0/24
          gateway: 192.168.111.1
          ip_range: 192.168.111.200/29
"@
}

Set-Content -Path $ComposePath -Value $composeContent -Encoding UTF8
Write-Success "docker-compose.yml generated at $ComposePath"

# ============================================
# STEP 8: SSH Key Generation
# ============================================
if ($SetupSSH -and $GenerateKey) {
    Write-Header "Step 8: Generating SSH Keys"

    # Ensure .ssh directory exists
    $sshDir = Join-Path $env:USERPROFILE ".ssh"
    if (-not (Test-Path $sshDir)) {
        New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
    }

    # Check if ssh-keygen is available
    $sshKeygen = Get-Command ssh-keygen -ErrorAction SilentlyContinue

    if ($sshKeygen) {
        Write-Host "Generating SSH key pair..." -ForegroundColor Cyan

        # Remove old key if overwriting
        if (Test-Path $SSHKeyPath) {
            Remove-Item $SSHKeyPath -Force
            Remove-Item "$SSHKeyPath.pub" -Force -ErrorAction SilentlyContinue
        }

        # Generate key
        & ssh-keygen -t ed25519 -f $SSHKeyPath -C "${ContainerUser}@${ContainerHostname}" -N '""' 2>&1 | Out-Null

        if (Test-Path $SSHKeyPath) {
            Write-Success "SSH key generated at $SSHKeyPath"

            # Create workspace/.ssh directory
            $workspaceSSHDir = Join-Path $ScriptDir "workspace\.ssh"
            if (-not (Test-Path $workspaceSSHDir)) {
                New-Item -ItemType Directory -Path $workspaceSSHDir -Force | Out-Null
            }

            # Copy public key to workspace
            $publicKeyPath = "$SSHKeyPath.pub"
            if (Test-Path $publicKeyPath) {
                $authorizedKeysPath = Join-Path $workspaceSSHDir "authorized_keys"
                Copy-Item $publicKeyPath $authorizedKeysPath -Force
                Write-Success "Public key copied to workspace/.ssh/authorized_keys"
            }

            # Update SSH config
            if ($UpdateSSHConfig) {
                $sshConfigPath = Join-Path $sshDir "config"
                $sshHostEntry = "Host $ContainerHostname"

                # Read existing config or create new
                $sshConfig = ""
                if (Test-Path $sshConfigPath) {
                    $sshConfig = Get-Content $sshConfigPath -Raw
                }

                # Check if entry already exists
                if ($sshConfig -match [regex]::Escape($sshHostEntry)) {
                    Write-Warning "SSH config entry for $ContainerHostname already exists"
                    if (Get-YesNo "Update existing SSH config entry?" $true) {
                        # Remove old entry (simple approach - remove from Host to next Host or EOF)
                        $sshConfig = $sshConfig -replace "(?ms)^Host $ContainerHostname\s*$.*?(?=^Host|\z)", ""
                    } else {
                        $UpdateSSHConfig = $false
                    }
                }

                if ($UpdateSSHConfig) {
                    # Add new entry
                    $newEntry = @"

Host $ContainerHostname
    HostName $ContainerIP
    User $ContainerUser
    IdentityFile $SSHKeyPath
    StrictHostKeyChecking no
    UserKnownHostsFile NUL

"@
                    $sshConfig += $newEntry
                    Set-Content -Path $sshConfigPath -Value $sshConfig -Encoding UTF8
                    Write-Success "SSH config updated at $sshConfigPath"
                }
            }
        } else {
            Write-Warning "SSH key generation failed"
        }
    } else {
        Write-Warning "ssh-keygen not found. Install OpenSSH or Git for Windows to generate keys."
        Write-Host "  You can install OpenSSH via: Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0" -ForegroundColor Yellow
        Write-Host "  Or download Git for Windows from: https://git-scm.com/download/win" -ForegroundColor Yellow
    }
}

# ============================================
# STEP 9: Create Helper PowerShell Scripts
# ============================================
Write-Header "Step 9: Creating Helper Scripts"

# Create copy-ssh-keys.ps1
$copySshKeysScript = @"
# Copy SSH keys to running Docker container

`$ContainerName = "$ContainerHostname"
`$ContainerUser = "$ContainerUser"
`$WorkspaceSSH = Join-Path `$PSScriptRoot "workspace\.ssh\authorized_keys"

Write-Host "Copying SSH authorized_keys to container..." -ForegroundColor Cyan

if (-not (Test-Path `$WorkspaceSSH)) {
    Write-Host "Error: authorized_keys not found at `$WorkspaceSSH" -ForegroundColor Red
    exit 1
}

# Check if container is running
`$containerRunning = docker ps --filter "name=`$ContainerName" --format "{{.Names}}" 2>`$null

if (`$containerRunning -eq `$ContainerName) {
    Write-Host "Container is running, copying keys..." -ForegroundColor Green

    docker exec `$ContainerName mkdir -p /home/`$ContainerUser/.ssh 2>`$null
    docker cp `$WorkspaceSSH "`${ContainerName}:/home/`$ContainerUser/.ssh/authorized_keys"
    docker exec `$ContainerName chown -R `$ContainerUser:`$ContainerUser /home/`$ContainerUser/.ssh
    docker exec `$ContainerName chmod 600 /home/`$ContainerUser/.ssh/authorized_keys

    Write-Host "✓ SSH keys copied successfully" -ForegroundColor Green
} else {
    Write-Host "Error: Container '$ContainerName' is not running" -ForegroundColor Red
    Write-Host "Start the container first with: docker-compose up -d" -ForegroundColor Yellow
    exit 1
}
"@

$copyKeysPath = Join-Path $ScriptDir "copy-ssh-keys.ps1"
Set-Content -Path $copyKeysPath -Value $copySshKeysScript -Encoding UTF8
Write-Success "Created copy-ssh-keys.ps1"

# Create deploy-to-portainer.md guide
$portainerGuide = @"
# Deploying to Portainer

This guide explains how to deploy the generated container in Portainer UI.

## Prerequisites

- Portainer installed and accessible
- Docker network '$NetworkName' $(if ($NetworkExternal) { "already exists" } else { "configured or created" })
- Generated Dockerfile and docker-compose.yml in this directory

## Deployment Steps

### Option 1: Using Portainer Stacks (Recommended)

1. **Login to Portainer** (usually at http://localhost:9000 or your server IP)

2. **Navigate to Stacks**
   - Click on "Stacks" in the left sidebar
   - Click "+ Add stack" button

3. **Configure the Stack**
   - Name: `$ContainerHostname` (or your preferred name)
   - Build method: Select "Repository" or "Upload"

4. **Upload Configuration**
   - If using "Upload": Upload your `docker-compose.yml`
   - If using "Repository": Point to your git repository

5. **Environment Variables (Optional)**
   - You can override settings here if needed

6. **Deploy the Stack**
   - Click "Deploy the stack"
   - Wait for the build and deployment to complete

7. **Copy SSH Keys (if configured)**
   - Open PowerShell in this directory
   - Run: ``````powershell
     .\copy-ssh-keys.ps1
     ``````

### Option 2: Using Portainer Containers

1. **Build the Image First**
   - Open PowerShell in this directory
   - Run: ``````powershell
     docker build -t $ContainerHostname:latest .
     ``````

2. **Login to Portainer**

3. **Create Container**
   - Click "Containers" in the left sidebar
   - Click "+ Add container"

4. **Configure Container**
   - **Name**: `$ContainerHostname`
   - **Image**: `$ContainerHostname:latest`
   - **Network**: Click "Add network" and select `$NetworkName`
     - Static IP: `$ContainerIP`
   - **Volumes**:
     - Container: `/app`
     - Host: `./workspace` (or full path to workspace directory)
   - **Restart policy**: Unless stopped
   - **Capabilities**: Add `NET_ADMIN`

5. **Deploy Container**
   - Click "Deploy the container"

6. **Copy SSH Keys (if configured)**
   - Run: ``````powershell
     .\copy-ssh-keys.ps1
     ``````

### Option 3: Using Docker Compose CLI

If you have Docker Compose installed locally:

``````powershell
# Build and start
docker-compose up -d

# Copy SSH keys
.\copy-ssh-keys.ps1
``````

## Network Configuration

$(if ($NetworkExternal) {
@"
Your configuration uses an **external network** named `$NetworkName`.

**Important:** Make sure this network exists before deploying!

To create it (if it doesn't exist):
``````powershell
docker network create -d macvlan \
  --subnet=192.168.111.0/24 \
  --gateway=192.168.111.1 \
  --ip-range=192.168.111.200/29 \
  -o parent=eth0 \
  $NetworkName
``````

Replace the subnet, gateway, and parent interface with your network settings.
"@
} else {
@"
Your configuration creates a **new macvlan network** named `$NetworkName`.

**Note:** You may need to adjust network settings in `docker-compose.yml`:
- `parent`: Your network interface (e.g., eth0, ens33)
- `subnet`: Your network subnet
- `gateway`: Your network gateway

If deploying via Portainer Stacks, the network will be created automatically.
If using Portainer Containers, create the network manually first:

``````powershell
docker network create -d macvlan \
  --subnet=192.168.111.0/24 \
  --gateway=192.168.111.1 \
  --ip-range=192.168.111.200/29 \
  -o parent=eth0 \
  $NetworkName
``````
"@
})

## After Deployment

### 1. Verify Container is Running

In Portainer:
- Go to "Containers"
- Check that `$ContainerHostname` is running (green status)
- View logs if there are any issues

Or via PowerShell:
``````powershell
docker ps | findstr $ContainerHostname
``````

### 2. Test SSH Connection

$(if ($SetupSSH) {
@"
Using the configured SSH shortcut:
``````powershell
ssh $ContainerHostname
``````

Or directly:
``````powershell
ssh ${ContainerUser}@${ContainerIP}
``````
"@
} else {
@"
``````powershell
ssh ${ContainerUser}@${ContainerIP}
# Password: [your configured password]
``````
"@
})

### 3. Setup LiteLLM (Optional - for Free Claude Code)

Once inside the container:
``````bash
# Setup LiteLLM
setup-litellm

# Edit .env and add your Google API key
nano ~/.config/litellm/.env

# Start LiteLLM proxy
~/.config/litellm/start-litellm.sh
``````

## Troubleshooting

### Container won't start

1. Check Portainer logs:
   - Click on the container
   - Click "Logs" tab
   - Look for error messages

2. Common issues:
   - Network doesn't exist (create it first)
   - Port conflicts (check if port 22 is already in use)
   - Volume mount issues (check path exists)

### Can't connect via SSH

1. Check container is running in Portainer
2. Check SSH service inside container:
   ``````powershell
   docker exec $ContainerHostname rc-service sshd status
   ``````
3. Try ping:
   ``````powershell
   ping $ContainerIP
   ``````
4. Check firewall settings

### SSH keys not working

1. Make sure you ran `copy-ssh-keys.ps1` AFTER container started
2. Check key permissions in container:
   ``````powershell
   docker exec $ContainerHostname ls -la /home/$ContainerUser/.ssh/
   ``````
3. Try password authentication first

## Connection Details

- **Hostname**: `$ContainerHostname`
- **IP Address**: `$ContainerIP`
- **Username**: `$ContainerUser`
- **Password**: [configured during setup]
$(if ($SetupSSH) {
@"
- **SSH Key**: `$SSHKeyPath`
"@
})

## Next Steps

1. SSH into your container
2. Run available helper commands:
   - `setup-claude` (if Claude CLI not auto-installed)
   - `install-ngrok` (if ngrok not auto-installed)
   - `setup-litellm` (for Claude Code + Gemini integration)
3. Start developing!

For more information, see the main README.md
"@

$portainerGuidePath = Join-Path $ScriptDir "PORTAINER_DEPLOYMENT.md"
Set-Content -Path $portainerGuidePath -Value $portainerGuide -Encoding UTF8
Write-Success "Created PORTAINER_DEPLOYMENT.md"

# ============================================
# FINAL: Summary and Next Steps
# ============================================
Write-Header "Setup Complete!"

Write-Host "Configuration files have been generated:" -ForegroundColor Green
Write-Host "  ✓ Dockerfile" -ForegroundColor Green
Write-Host "  ✓ docker-compose.yml" -ForegroundColor Green
if ($SetupSSH -and (Test-Path $SSHKeyPath)) {
    Write-Host "  ✓ SSH keys generated" -ForegroundColor Green
    Write-Host "  ✓ SSH config updated" -ForegroundColor Green
}
Write-Host "  ✓ copy-ssh-keys.ps1" -ForegroundColor Green
Write-Host "  ✓ PORTAINER_DEPLOYMENT.md" -ForegroundColor Green
Write-Host ""

Write-Host "Container Configuration:" -ForegroundColor Cyan
Write-Host "  Hostname: $ContainerHostname"
Write-Host "  IP Address: $ContainerIP"
Write-Host "  Username: $ContainerUser"
Write-Host "  Network: $NetworkName"
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Option 1 - Deploy via Portainer UI:" -ForegroundColor White
Write-Host "  1. Read PORTAINER_DEPLOYMENT.md for detailed instructions"
Write-Host "  2. Open Portainer web interface"
Write-Host "  3. Create a new Stack using docker-compose.yml"
Write-Host "  4. After deployment, run: .\copy-ssh-keys.ps1"
Write-Host ""
Write-Host "Option 2 - Deploy via Docker Compose:" -ForegroundColor White
Write-Host "  1. docker-compose up -d"
Write-Host "  2. .\copy-ssh-keys.ps1"
Write-Host ""
Write-Host "Option 3 - Build image only:" -ForegroundColor White
Write-Host "  1. docker build -t ${ContainerHostname}:latest ."
Write-Host "  2. Deploy the image manually in Portainer"
Write-Host "  3. .\copy-ssh-keys.ps1"
Write-Host ""

if ($SetupSSH) {
    Write-Host "Connect to container:" -ForegroundColor Cyan
    Write-Host "  ssh $ContainerHostname" -ForegroundColor Green
    Write-Host "  or" -ForegroundColor Gray
    Write-Host "  ssh ${ContainerUser}@${ContainerIP}" -ForegroundColor Green
} else {
    Write-Host "Connect to container:" -ForegroundColor Cyan
    Write-Host "  ssh ${ContainerUser}@${ContainerIP}" -ForegroundColor Green
}

Write-Host ""
Write-Host "For detailed Portainer deployment instructions, see:" -ForegroundColor Yellow
Write-Host "  PORTAINER_DEPLOYMENT.md" -ForegroundColor White
Write-Host ""

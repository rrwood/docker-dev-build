# SSH Setup Guide - Connect from Your Host to Container

This guide explains how to set up SSH key authentication from your host machine to the container.

## Quick Start

**Goal:** SSH into your container without typing a password every time.

```bash
# Simple connection:
ssh username@container-ip

# After setup:
ssh my-container    # Just an alias!
```

---

## Method 1: Use Your Existing SSH Key (Recommended)

Most users already have an SSH key at `~/.ssh/id_rsa.pub`. Use this method if you already have one.

### Step 1: Check if You Have a Key

**Linux/Mac:**
```bash
ls -la ~/.ssh/id_rsa.pub
```

**Windows PowerShell:**
```powershell
ls ~\.ssh\id_rsa.pub
```

**If the file exists**, proceed to Step 2.  
**If not**, skip to Method 2 to create one.

### Step 2: Copy Your Public Key to Container

**Linux/Mac:**
```bash
# Easy way (recommended):
ssh-copy-id username@container-ip

# Example:
ssh-copy-id devuser@192.168.111.15

# Manual way:
cat ~/.ssh/id_rsa.pub | ssh username@container-ip "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

**Windows PowerShell:**
```powershell
# Get your public key content:
type ~\.ssh\id_rsa.pub | ssh username@container-ip "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

# Example:
type ~\.ssh\id_rsa.pub | ssh devuser@192.168.111.15 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

**Windows CMD:**
```cmd
type %USERPROFILE%\.ssh\id_rsa.pub | ssh username@container-ip "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### Step 3: Configure SSH Alias (Optional but Recommended)

Edit your SSH config file to create a short alias.

**Linux/Mac:**
```bash
# Create/edit config file
nano ~/.ssh/config

# Add this:
Host my-container
    HostName 192.168.111.15
    User devuser
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

# Now you can just type:
ssh my-container
```

**Windows:**
```powershell
# Create/edit config file
notepad ~\.ssh\config

# Add this:
Host my-container
    HostName 192.168.111.15
    User devuser
    IdentityFile C:\Users\YourUsername\.ssh\id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

# Now you can just type:
ssh my-container
```

### Step 4: Test Connection

```bash
ssh my-container
# or
ssh username@container-ip
```

Should connect **without asking for password**! ✅

---

## Method 2: Generate a New SSH Key

Use this if you don't have an SSH key yet, or want a dedicated key for this container.

### Step 1: Generate Key on Your Host Machine

**Linux/Mac:**
```bash
# Generate new key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/docker-dev-key -C "your-email@example.com"

# Press Enter for no passphrase, or enter one for extra security
```

**Windows PowerShell:**
```powershell
# Generate new key
ssh-keygen -t rsa -b 4096 -f ~\.ssh\docker-dev-key

# Press Enter for no passphrase, or enter one for extra security
```

This creates:
- `~/.ssh/docker-dev-key` (private key - keep secret!)
- `~/.ssh/docker-dev-key.pub` (public key - safe to share)

### Step 2: Copy Public Key to Container

**Linux/Mac:**
```bash
# Copy to container
cat ~/.ssh/docker-dev-key.pub | ssh username@container-ip "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

# Example:
cat ~/.ssh/docker-dev-key.pub | ssh devuser@192.168.111.15 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

**Windows PowerShell:**
```powershell
type ~\.ssh\docker-dev-key.pub | ssh username@container-ip "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# Example:
type ~\.ssh\docker-dev-key.pub | ssh devuser@192.168.111.15 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### Step 3: Configure SSH to Use This Key

**Linux/Mac:**
```bash
# Edit SSH config
nano ~/.ssh/config

# Add this:
Host my-container
    HostName 192.168.111.15
    User devuser
    IdentityFile ~/.ssh/docker-dev-key
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

**Windows:**
```powershell
# Edit SSH config
notepad ~\.ssh\config

# Add this:
Host my-container
    HostName 192.168.111.15
    User devuser
    IdentityFile C:\Users\YourUsername\.ssh\docker-dev-key
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

### Step 4: Test Connection

```bash
ssh my-container
```

Should connect without password! ✅

---

## Method 3: Use Container-Generated Key (Less Common)

If you want to generate the key **inside the container** and copy the private key to your host.

### Step 1: Generate Key Inside Container

```bash
# SSH into container
ssh devuser@192.168.111.15

# Generate key inside container
cd ~/setup
./generate-ssh-keys.sh

# This creates:
# ~/.ssh/id_rsa (private)
# ~/.ssh/id_rsa.pub (public)
```

### Step 2: Display Private Key

```bash
# Inside container
cat ~/.ssh/id_rsa
```

Copy the **entire output** (including `-----BEGIN OPENSSH PRIVATE KEY-----` and `-----END OPENSSH PRIVATE KEY-----`).

### Step 3: Save to Host Machine

**Linux/Mac:**
```bash
# On your host machine
nano ~/.ssh/container-key

# Paste the private key
# Save and exit (Ctrl+X, Y, Enter)

# Set correct permissions
chmod 600 ~/.ssh/container-key
```

**Windows:**
```powershell
# On your host machine
notepad ~\.ssh\container-key

# Paste the private key
# Save and close

# Set permissions (PowerShell as Admin):
icacls ~\.ssh\container-key /inheritance:r
icacls ~\.ssh\container-key /grant:r "$($env:USERNAME):(R)"
```

### Step 4: Configure SSH Config

**Linux/Mac:**
```bash
nano ~/.ssh/config

# Add:
Host my-container
    HostName 192.168.111.15
    User devuser
    IdentityFile ~/.ssh/container-key
    StrictHostKeyChecking no
```

**Windows:**
```powershell
notepad ~\.ssh\config

# Add:
Host my-container
    HostName 192.168.111.15
    User devuser
    IdentityFile C:\Users\YourUsername\.ssh\container-key
    StrictHostKeyChecking no
```

---

## SSH Config File Explained

The `~/.ssh/config` file lets you create shortcuts and set default options.

### Basic Example

```
Host my-container
    HostName 192.168.111.15
    User devuser
    IdentityFile ~/.ssh/id_rsa
```

Now instead of:
```bash
ssh -i ~/.ssh/id_rsa devuser@192.168.111.15
```

Just type:
```bash
ssh my-container
```

### Advanced Example

```
Host dev1
    HostName 192.168.111.15
    User devuser
    IdentityFile ~/.ssh/docker-dev-key
    Port 22
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ServerAliveInterval 60
    ServerAliveCountMax 3

Host dev2
    HostName 192.168.111.16
    User admin
    IdentityFile ~/.ssh/another-key
```

### Config Options Explained

| Option | What It Does |
|--------|--------------|
| `Host` | The alias you'll type (e.g., `ssh my-container`) |
| `HostName` | The actual IP address or domain |
| `User` | The username to login as |
| `IdentityFile` | Path to your private key |
| `Port` | SSH port (default: 22) |
| `StrictHostKeyChecking no` | Don't ask about host key verification |
| `UserKnownHostsFile /dev/null` | Don't save host key (useful for containers that get rebuilt) |
| `ServerAliveInterval 60` | Send keepalive every 60 seconds |
| `ServerAliveCountMax 3` | Disconnect after 3 failed keepalives |

### Multiple Containers Example

```
# Development container
Host dev
    HostName 192.168.111.15
    User devuser
    IdentityFile ~/.ssh/docker-dev-key

# Production container
Host prod
    HostName 192.168.111.20
    User admin
    IdentityFile ~/.ssh/prod-key
    Port 2222

# Test container
Host test
    HostName 192.168.111.25
    User devuser
    IdentityFile ~/.ssh/id_rsa
```

Then:
```bash
ssh dev    # Connect to development
ssh prod   # Connect to production
ssh test   # Connect to test
```

---

## Troubleshooting

### Permission Denied (publickey)

**Cause:** Container doesn't have your public key in `authorized_keys`.

**Fix:**
```bash
# Copy your public key again
cat ~/.ssh/id_rsa.pub | ssh username@container-ip "cat >> ~/.ssh/authorized_keys"

# Or from inside container:
# Paste your public key manually
nano ~/.ssh/authorized_keys
# Paste, save, exit
chmod 600 ~/.ssh/authorized_keys
```

### Still Asking for Password

**Check these:**

1. **Permissions on container:**
```bash
# Inside container
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
ls -la ~/.ssh/
# Should show drwx------ for .ssh directory
# Should show -rw------- for authorized_keys
```

2. **Permissions on host (Linux/Mac):**
```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

3. **Check SSH config is being used:**
```bash
ssh -v my-container
# Look for "Reading configuration data" in output
```

4. **Try specifying key manually:**
```bash
ssh -i ~/.ssh/id_rsa username@container-ip
```

### Connection Timeout

**Cause:** Network/firewall issue.

**Fix:**
```bash
# Test if container is reachable
ping 192.168.111.15

# Test if SSH port is open
telnet 192.168.111.15 22

# Check container is running
docker ps | grep docker-dev

# Check SSH service in container
docker exec docker-dev rc-service sshd status
```

### Wrong Key Being Used

**Check which keys SSH is trying:**
```bash
ssh -v my-container 2>&1 | grep "identity file"
```

**Force specific key:**
```bash
ssh -i ~/.ssh/specific-key username@container-ip
```

### Key Not Found Error

**Windows Path Issues:**

If using Windows, make sure paths use backslashes OR forward slashes consistently:

```
# Either of these works in SSH config:
IdentityFile C:/Users/YourName/.ssh/id_rsa
IdentityFile C:\Users\YourName\.ssh\id_rsa
IdentityFile ~/.ssh/id_rsa
```

---

## Quick Reference

### Copy Default Key to Container

**Linux/Mac:**
```bash
ssh-copy-id devuser@192.168.111.15
```

**Windows:**
```powershell
type ~\.ssh\id_rsa.pub | ssh devuser@192.168.111.15 "cat >> ~/.ssh/authorized_keys"
```

### Create SSH Alias

```bash
# Edit config
nano ~/.ssh/config   # Linux/Mac
notepad ~\.ssh\config  # Windows

# Add:
Host mydev
    HostName 192.168.111.15
    User devuser
    IdentityFile ~/.ssh/id_rsa

# Use:
ssh mydev
```

### Fix Permissions (Inside Container)

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

### Test SSH Connection

```bash
# With password
ssh devuser@192.168.111.15

# With key (auto)
ssh mydev

# With key (manual)
ssh -i ~/.ssh/id_rsa devuser@192.168.111.15

# Verbose (for troubleshooting)
ssh -v devuser@192.168.111.15
```

---

## Security Notes

- **Never share your private key** (the file without `.pub`)
- **Public keys are safe to share** (the `.pub` file)
- **Use passphrases** for extra security on private keys
- **Keep private keys at 600 permissions** (owner read/write only)
- **Keep `~/.ssh` directory at 700 permissions** (owner access only)

---

**Need help?** See the main README.md or check the container's `~/setup/README.md`

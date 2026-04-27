# Setup Helper Scripts

This directory contains helper scripts for post-deployment configuration.

## 📋 Available Scripts

### 🔐 Security & Access

#### `change-password.sh`
Change your user password interactively.

```bash
./change-password.sh
```

**What it does:**
- Prompts for current password
- Asks for new password (with confirmation)
- Updates your user password
- Shows tips for SSH key setup

**When to use:**
- Immediately after first deployment (to change default password)
- Anytime you want to update your password

---

#### `generate-ssh-keys.sh`
Generate SSH key pairs for password-less authentication.

```bash
./generate-ssh-keys.sh
```

**What it does:**
- Checks for existing keys (offers to backup if found)
- Generates RSA 4096-bit key pair
- Displays your public key
- Optionally adds key to authorized_keys
- Shows instructions for client-side setup

**When to use:**
- After changing your password
- When setting up password-less SSH access
- When you need to generate new keys

---

### 📊 Information & Diagnostics

#### `container-info.sh`
Display comprehensive container information.

```bash
./container-info.sh
```

**What it shows:**
- User information (username, UID, GID, home directory)
- System information (hostname, OS, kernel)
- Network configuration (IP addresses)
- Installed tools (Claude, LiteLLM, ngrok, etc.)
- Disk and memory usage
- SSH key status

**When to use:**
- Verify container configuration
- Check what tools are installed
- Troubleshooting network issues
- Before opening support tickets

---

#### `welcome-motd.sh`
Welcome message displayed on login.

**Note:** This runs automatically via `/etc/profile.d/welcome.sh`

**Shows:**
- Quick start checklist
- Available tools
- Documentation links
- Common commands

---

## 📖 Documentation

#### `README.md`
Complete post-deployment setup guide.

**Covers:**
- First steps (password change, SSH keys)
- Installing optional tools (Claude CLI, ngrok, LiteLLM)
- Troubleshooting
- SSH configuration examples
- Container information

---

## 🎯 Recommended Setup Workflow

**Step 1: Security First**
```bash
cd ~/setup
./change-password.sh
```

**Step 2: SSH Keys**
```bash
./generate-ssh-keys.sh
```

**Step 3: Verify Setup**
```bash
./container-info.sh
```

**Step 4: Install Tools** (as needed)
```bash
# Install Claude CLI
setup-claude

# Install LiteLLM
setup-litellm

# Install ngrok (if not done during build)
install-ngrok YOUR_TOKEN
```

---

## 💡 Tips

### SSH Key Best Practices

1. **Generate keys on first login**
   - More secure than password-only authentication
   - Easier to manage multiple client machines
   - Can be revoked individually

2. **Backup your keys**
   - Keys are stored in `~/.ssh/`
   - Backup both private (`id_rsa`) and public (`id_rsa.pub`) keys
   - Old keys are automatically backed up when regenerating

3. **Use different keys for different purposes**
   - Generate separate keys for different access levels
   - Use ssh-agent for key management

### Password Guidelines

- **Minimum 12 characters**
- **Mix of uppercase, lowercase, numbers, symbols**
- **Avoid common words or patterns**
- **Don't reuse passwords from other services**

### Container Maintenance

```bash
# Check disk space regularly
df -h

# Update package lists
sudo apk update

# View running processes
ps aux

# Check memory usage
free -h

# View system logs
dmesg | tail -50
```

---

## 🆘 Troubleshooting

### Can't change password

**Issue:** `passwd` command fails

**Solutions:**
- Make sure you're not running as root
- Check password meets complexity requirements
- Verify current password is correct

---

### SSH key generation fails

**Issue:** `ssh-keygen` command fails

**Solutions:**
- Check `~/.ssh/` directory exists and is writable
- Verify disk space: `df -h ~`
- Check permissions: `ls -la ~/.ssh/`

---

### Permission denied errors

**Issue:** Can't write to files/directories

**Solutions:**
```bash
# Fix .ssh permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*
chown -R $(whoami):$(whoami) ~/.ssh

# Fix setup directory permissions
chmod 755 ~/setup
chmod +x ~/setup/*.sh
```

---

## 📚 Additional Resources

- **Main Repository:** https://github.com/rrwood/docker-dev-build
- **Portainer Guide:** See PORTAINER_DEPLOY.md
- **LiteLLM Docs:** https://docs.litellm.ai/
- **Claude Code Docs:** https://claude.ai/docs

---

**Questions?** Check the main README.md or open an issue on GitHub.

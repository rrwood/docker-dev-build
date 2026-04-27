#!/bin/bash
#
# Docker Development Container Setup Script
# Interactively configures and builds a customized development container
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKERFILE="$SCRIPT_DIR/Dockerfile"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
SSH_KEY_NAME="docker-dev-container"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_header() {
    echo -e "\n${BLUE}======================================"
    echo -e "$1"
    echo -e "======================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Prompt for yes/no
prompt_yes_no() {
    local prompt="$1"
    local default="$2"
    local response

    if [ "$default" = "y" ]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi

    read -p "$prompt" response
    response=${response:-$default}

    if [[ "$response" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Prompt for input with default
prompt_input() {
    local prompt="$1"
    local default="$2"
    local response

    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " response
        echo "${response:-$default}"
    else
        read -p "$prompt: " response
        echo "$response"
    fi
}

# Prompt for password (hidden input)
prompt_password() {
    local prompt="$1"
    local password
    local password_confirm

    while true; do
        read -s -p "$prompt: " password
        echo
        read -s -p "Confirm password: " password_confirm
        echo

        if [ "$password" = "$password_confirm" ]; then
            if [ -z "$password" ]; then
                print_error "Password cannot be empty"
                continue
            fi
            echo "$password"
            return 0
        else
            print_error "Passwords do not match, please try again"
        fi
    done
}

print_header "Docker Development Container Setup"

echo "This script will help you configure and build a customized development container."
echo ""

# Read docker-compose.yml to get current IP
CURRENT_IP=$(grep "ipv4_address:" "$COMPOSE_FILE" 2>/dev/null | awk '{print $2}' || echo "192.168.111.15")
CURRENT_HOSTNAME=$(grep "hostname:" "$COMPOSE_FILE" 2>/dev/null | awk '{print $2}' || echo "docker-dev")

# ============================================
# STEP 1: Basic Configuration
# ============================================
print_header "Step 1: Basic Configuration"

CONTAINER_USER=$(prompt_input "Enter username for container user" "devuser")
CONTAINER_PASS=$(prompt_password "Enter password for $CONTAINER_USER")
CONTAINER_HOSTNAME=$(prompt_input "Enter container hostname" "$CURRENT_HOSTNAME")
CONTAINER_IP=$(prompt_input "Enter container IP address" "$CURRENT_IP")

# ============================================
# STEP 2: Optional Components
# ============================================
print_header "Step 2: Optional Components"

if prompt_yes_no "Install Claude CLI automatically?" "y"; then
    INSTALL_CLAUDE=true
else
    INSTALL_CLAUDE=false
fi

if prompt_yes_no "Install ngrok automatically?" "n"; then
    INSTALL_NGROK=true
    if [ "$INSTALL_NGROK" = true ]; then
        NGROK_TOKEN=$(prompt_input "Enter ngrok auth token (leave empty to skip)" "")
    fi
else
    INSTALL_NGROK=false
fi

# ============================================
# STEP 3: SSH Configuration
# ============================================
print_header "Step 3: SSH Configuration"

if prompt_yes_no "Will you access this container from THIS machine?" "y"; then
    SETUP_SSH=true
    SSH_KEY_PATH="$HOME/.ssh/${SSH_KEY_NAME}"

    echo ""
    echo "SSH key will be created at: $SSH_KEY_PATH"

    if [ -f "$SSH_KEY_PATH" ]; then
        print_warning "SSH key already exists at $SSH_KEY_PATH"
        if ! prompt_yes_no "Overwrite existing key?" "n"; then
            print_warning "Using existing key"
            GENERATE_KEY=false
        else
            GENERATE_KEY=true
        fi
    else
        GENERATE_KEY=true
    fi
else
    SETUP_SSH=false
fi

# ============================================
# STEP 4: Summary
# ============================================
print_header "Configuration Summary"

echo "Container Settings:"
echo "  Hostname: $CONTAINER_HOSTNAME"
echo "  IP Address: $CONTAINER_IP"
echo "  Username: $CONTAINER_USER"
echo "  Password: ${CONTAINER_PASS//?/*}"
echo ""
echo "Optional Components:"
echo "  Claude CLI: $([ "$INSTALL_CLAUDE" = true ] && echo "Yes" || echo "No")"
echo "  ngrok: $([ "$INSTALL_NGROK" = true ] && echo "Yes" || echo "No")"
echo ""
echo "SSH Configuration:"
echo "  Setup SSH from this host: $([ "$SETUP_SSH" = true ] && echo "Yes" || echo "No")"
if [ "$SETUP_SSH" = true ]; then
    echo "  SSH Key: $SSH_KEY_PATH"
fi
echo ""

if ! prompt_yes_no "Proceed with this configuration?" "y"; then
    print_error "Setup cancelled"
    exit 1
fi

# ============================================
# STEP 5: Generate Dockerfile
# ============================================
print_header "Step 5: Generating Dockerfile"

cat > "$DOCKERFILE" << 'DOCKERFILE_START'
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

DOCKERFILE_START

# Add Claude CLI installation
if [ "$INSTALL_CLAUDE" = true ]; then
    cat >> "$DOCKERFILE" << 'CLAUDE_INSTALL'

# Install Claude CLI
RUN curl -fsSL https://claude.ai/install.sh | sh

CLAUDE_INSTALL
    print_success "Added Claude CLI installation to Dockerfile"
else
    print_warning "Skipped Claude CLI installation (use setup-claude script in container)"
fi

# Add ngrok installation
if [ "$INSTALL_NGROK" = true ]; then
    cat >> "$DOCKERFILE" << 'NGROK_INSTALL'

# Install ngrok
RUN wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz && \
    tar xvzf ngrok-v3-stable-linux-amd64.tgz && \
    mv ngrok /usr/local/bin/ && \
    rm ngrok-v3-stable-linux-amd64.tgz && \
    chmod +x /usr/local/bin/ngrok

NGROK_INSTALL

    if [ -n "$NGROK_TOKEN" ]; then
        cat >> "$DOCKERFILE" << NGROK_TOKEN_INSTALL

# Configure ngrok auth token
RUN ngrok config add-authtoken ${NGROK_TOKEN}

NGROK_TOKEN_INSTALL
        print_success "Added ngrok installation with auth token to Dockerfile"
    else
        print_success "Added ngrok installation to Dockerfile (no auth token)"
    fi
else
    print_warning "Skipped ngrok installation (use install-ngrok script in container)"
fi

# Add SSH configuration and user setup
cat >> "$DOCKERFILE" << DOCKERFILE_SSH

# Setup SSH - disable root login, allow user login with password and keys
RUN ssh-keygen -A && \\
    sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && \\
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \\
    sed -i 's/#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \\
    sed -i 's/#AuthorizedKeysFile.*/AuthorizedKeysFile .ssh\/authorized_keys/' /etc/ssh/sshd_config

# Create user: ${CONTAINER_USER}
RUN adduser -D -s /bin/bash ${CONTAINER_USER} && \\
    echo '${CONTAINER_USER}:${CONTAINER_PASS}' | chpasswd && \\
    mkdir -p /home/${CONTAINER_USER}/.ssh && \\
    chmod 700 /home/${CONTAINER_USER}/.ssh && \\
    chown -R ${CONTAINER_USER}:${CONTAINER_USER} /home/${CONTAINER_USER}/.ssh && \\
    echo '${CONTAINER_USER} ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/${CONTAINER_USER}

# Copy helper scripts
COPY scripts/install-ngrok.sh /usr/local/bin/install-ngrok
COPY scripts/setup-litellm.sh /usr/local/bin/setup-litellm
COPY scripts/setup-claude.sh /usr/local/bin/setup-claude
RUN chmod +x /usr/local/bin/install-ngrok /usr/local/bin/setup-litellm /usr/local/bin/setup-claude

# Create working directory
WORKDIR /app
RUN chown ${CONTAINER_USER}:${CONTAINER_USER} /app

# Expose SSH port
EXPOSE 22

# Keep container running and start SSH
CMD ["/usr/sbin/sshd", "-D"]
DOCKERFILE_SSH

print_success "Dockerfile generated successfully"

# ============================================
# STEP 6: Update docker-compose.yml
# ============================================
print_header "Step 6: Updating docker-compose.yml"

# Read existing network configuration
NETWORK_NAME=$(grep -A 1 "networks:" "$COMPOSE_FILE" | tail -1 | sed 's/://g' | xargs)
IS_EXTERNAL=$(grep "external: true" "$COMPOSE_FILE" &>/dev/null && echo "true" || echo "false")

cat > "$COMPOSE_FILE" << COMPOSE_START
version: '3.8'

services:
  ${CONTAINER_HOSTNAME}:
    build: .
    container_name: ${CONTAINER_HOSTNAME}
    hostname: ${CONTAINER_HOSTNAME}
    restart: unless-stopped
    networks:
      ${NETWORK_NAME}:
        ipv4_address: ${CONTAINER_IP}
    volumes:
      - ./workspace:/app
    cap_add:
      - NET_ADMIN

networks:
  ${NETWORK_NAME}:
COMPOSE_START

if [ "$IS_EXTERNAL" = "true" ]; then
    echo "    external: true" >> "$COMPOSE_FILE"
else
    # Try to preserve existing network config
    if grep -q "subnet:" "$COMPOSE_FILE.bak" 2>/dev/null; then
        grep -A 5 "ipam:" "$COMPOSE_FILE.bak" >> "$COMPOSE_FILE"
    fi
fi

print_success "docker-compose.yml updated"

# ============================================
# STEP 7: Create setup-claude script
# ============================================
print_header "Step 7: Creating helper scripts"

cat > "$SCRIPT_DIR/scripts/setup-claude.sh" << 'SETUP_CLAUDE'
#!/bin/bash
#
# Claude CLI Installation Script
# Usage: setup-claude
#

set -e

echo "Installing Claude CLI..."
curl -fsSL https://claude.ai/install.sh | sh

echo ""
echo "✓ Claude CLI installed successfully!"
echo ""
echo "Run 'claude' to get started"
SETUP_CLAUDE

chmod +x "$SCRIPT_DIR/scripts/setup-claude.sh"
print_success "Helper scripts updated"

# ============================================
# STEP 8: SSH Key Setup
# ============================================
if [ "$SETUP_SSH" = true ]; then
    print_header "Step 8: Setting up SSH"

    # Generate SSH key if needed
    if [ "$GENERATE_KEY" = true ]; then
        echo "Generating SSH key..."
        ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -C "${CONTAINER_USER}@${CONTAINER_HOSTNAME}" -N ""
        print_success "SSH key generated at $SSH_KEY_PATH"
    fi

    # Create workspace directory if it doesn't exist
    mkdir -p "$SCRIPT_DIR/workspace"

    # Copy public key to workspace (will be copied to container)
    mkdir -p "$SCRIPT_DIR/workspace/.ssh"
    cp "${SSH_KEY_PATH}.pub" "$SCRIPT_DIR/workspace/.ssh/authorized_keys"
    print_success "Public key copied to workspace"

    # Update SSH config
    SSH_CONFIG="$HOME/.ssh/config"
    SSH_HOST_ENTRY="Host ${CONTAINER_HOSTNAME}"

    if grep -q "$SSH_HOST_ENTRY" "$SSH_CONFIG" 2>/dev/null; then
        print_warning "SSH config entry for $CONTAINER_HOSTNAME already exists"
        if prompt_yes_no "Update existing SSH config entry?" "y"; then
            # Remove old entry
            sed -i.bak "/Host ${CONTAINER_HOSTNAME}/,/^$/d" "$SSH_CONFIG"
        else
            SSH_UPDATE_CONFIG=false
        fi
    fi

    if [ "${SSH_UPDATE_CONFIG:-true}" = true ]; then
        cat >> "$SSH_CONFIG" << SSH_ENTRY

Host ${CONTAINER_HOSTNAME}
    HostName ${CONTAINER_IP}
    User ${CONTAINER_USER}
    IdentityFile ${SSH_KEY_PATH}
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

SSH_ENTRY
        print_success "SSH config updated at $SSH_CONFIG"
    fi

    # Create a post-build script to copy SSH keys
    cat > "$SCRIPT_DIR/copy-ssh-keys.sh" << COPY_KEYS
#!/bin/bash
# Copy SSH authorized_keys to running container

CONTAINER_NAME="${CONTAINER_HOSTNAME}"
CONTAINER_USER="${CONTAINER_USER}"

echo "Waiting for container to start..."
sleep 3

if docker ps | grep -q "\$CONTAINER_NAME"; then
    echo "Copying SSH authorized_keys to container..."
    docker exec \$CONTAINER_NAME mkdir -p /home/\$CONTAINER_USER/.ssh
    docker cp workspace/.ssh/authorized_keys \$CONTAINER_NAME:/home/\$CONTAINER_USER/.ssh/authorized_keys
    docker exec \$CONTAINER_NAME chown -R \$CONTAINER_USER:\$CONTAINER_USER /home/\$CONTAINER_USER/.ssh
    docker exec \$CONTAINER_NAME chmod 600 /home/\$CONTAINER_USER/.ssh/authorized_keys
    echo "✓ SSH keys copied successfully"
else
    echo "✗ Container not running"
    exit 1
fi
COPY_KEYS
    chmod +x "$SCRIPT_DIR/copy-ssh-keys.sh"
    print_success "SSH key copy script created"
fi

# ============================================
# STEP 9: Build Container
# ============================================
print_header "Step 9: Build and Start Container"

if prompt_yes_no "Build and start the container now?" "y"; then
    echo "Building container..."
    cd "$SCRIPT_DIR"
    docker-compose build
    print_success "Container built successfully"

    echo "Starting container..."
    docker-compose up -d
    print_success "Container started"

    if [ "$SETUP_SSH" = true ]; then
        echo "Copying SSH keys to container..."
        "$SCRIPT_DIR/copy-ssh-keys.sh"
    fi

    # ============================================
    # FINAL: Success and Next Steps
    # ============================================
    print_header "Setup Complete!"

    echo -e "${GREEN}Container is running and ready to use!${NC}"
    echo ""
    echo "Connection Information:"
    echo "  Hostname: $CONTAINER_HOSTNAME"
    echo "  IP Address: $CONTAINER_IP"
    echo "  Username: $CONTAINER_USER"
    echo "  Password: ${CONTAINER_PASS//?/*}"
    echo ""

    if [ "$SETUP_SSH" = true ]; then
        echo "SSH Connection:"
        echo -e "  ${BLUE}ssh $CONTAINER_HOSTNAME${NC}"
        echo "  or"
        echo -e "  ${BLUE}ssh ${CONTAINER_USER}@${CONTAINER_IP}${NC}"
        echo ""
    else
        echo "SSH Connection:"
        echo -e "  ${BLUE}ssh ${CONTAINER_USER}@${CONTAINER_IP}${NC}"
        echo ""
    fi

    echo "Docker Commands:"
    echo -e "  ${BLUE}docker exec -it $CONTAINER_HOSTNAME su - $CONTAINER_USER${NC}"
    echo ""

    echo "Available Commands in Container:"
    if [ "$INSTALL_CLAUDE" = false ]; then
        echo "  setup-claude       - Install Claude CLI"
    fi
    if [ "$INSTALL_NGROK" = false ]; then
        echo "  install-ngrok      - Install ngrok"
    fi
    echo "  setup-litellm      - Setup Claude Code + Gemini integration"
    echo ""

    echo "Next Steps:"
    echo "  1. SSH into the container"
    if [ "$INSTALL_CLAUDE" = false ]; then
        echo "  2. Run 'setup-claude' to install Claude CLI"
    fi
    echo "  2. Run 'setup-litellm' to configure Claude Code with Gemini"
    echo "  3. Start coding!"
    echo ""

    if [ "$SETUP_SSH" = true ]; then
        print_success "Testing SSH connection in 5 seconds..."
        sleep 5
        ssh -o ConnectTimeout=5 "$CONTAINER_HOSTNAME" "echo 'SSH connection successful!'" && \
            print_success "SSH connection verified!" || \
            print_warning "Could not verify SSH connection. Try manually: ssh $CONTAINER_HOSTNAME"
    fi
else
    print_header "Setup Complete (Build Skipped)"

    echo "Configuration files have been generated."
    echo ""
    echo "To build and start the container manually:"
    echo -e "  ${BLUE}docker-compose build${NC}"
    echo -e "  ${BLUE}docker-compose up -d${NC}"

    if [ "$SETUP_SSH" = true ]; then
        echo -e "  ${BLUE}./copy-ssh-keys.sh${NC}"
    fi
    echo ""
fi

echo "For more information, see README.md"
echo ""

#!/bin/bash
#
# Verification Script for Docker Development Container
# Checks if container is properly configured and accessible
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

ERRORS=0

print_header "Docker Development Container Verification"

# Check Docker is running
print_header "Checking Docker"
if ! docker info &>/dev/null; then
    print_error "Docker is not running"
    exit 1
fi
print_success "Docker is running"

# Check docker-compose.yml exists
print_header "Checking Configuration Files"
if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found"
    ((ERRORS++))
else
    print_success "docker-compose.yml exists"
fi

if [ ! -f "Dockerfile" ]; then
    print_error "Dockerfile not found"
    ((ERRORS++))
else
    print_success "Dockerfile exists"
fi

# Get container info from docker-compose.yml
CONTAINER_NAME=$(grep "container_name:" docker-compose.yml | awk '{print $2}')
CONTAINER_IP=$(grep "ipv4_address:" docker-compose.yml | awk '{print $2}')

echo "  Container name: $CONTAINER_NAME"
echo "  Container IP: $CONTAINER_IP"

# Check if container is running
print_header "Checking Container Status"
if docker ps | grep -q "$CONTAINER_NAME"; then
    print_success "Container is running"

    # Get container uptime
    UPTIME=$(docker ps --filter "name=$CONTAINER_NAME" --format "{{.Status}}")
    echo "  Status: $UPTIME"
else
    print_error "Container is not running"
    if docker ps -a | grep -q "$CONTAINER_NAME"; then
        print_warning "Container exists but is stopped"
        echo "  Try: docker-compose up -d"
    else
        print_warning "Container does not exist"
        echo "  Try: docker-compose build && docker-compose up -d"
    fi
    ((ERRORS++))
fi

# Check network connectivity
print_header "Checking Network Connectivity"
if ping -c 1 -W 2 "$CONTAINER_IP" &>/dev/null; then
    print_success "Container is reachable at $CONTAINER_IP"
else
    print_error "Cannot ping container at $CONTAINER_IP"
    print_warning "This might be normal depending on network configuration"
fi

# Check SSH service
print_header "Checking SSH Service"
if docker ps | grep -q "$CONTAINER_NAME"; then
    if docker exec "$CONTAINER_NAME" rc-service sshd status &>/dev/null; then
        print_success "SSH service is running in container"
    else
        print_error "SSH service is not running in container"
        ((ERRORS++))
    fi

    # Check if port 22 is listening
    if docker exec "$CONTAINER_NAME" netstat -tuln 2>/dev/null | grep -q ":22 "; then
        print_success "SSH port 22 is listening"
    else
        print_warning "SSH port 22 might not be listening"
    fi
fi

# Check SSH config
print_header "Checking SSH Configuration"
if [ -f "$HOME/.ssh/config" ]; then
    if grep -q "Host $CONTAINER_NAME" "$HOME/.ssh/config" 2>/dev/null; then
        print_success "SSH config entry exists for $CONTAINER_NAME"

        # Check SSH key
        SSH_KEY=$(grep -A 5 "Host $CONTAINER_NAME" "$HOME/.ssh/config" | grep "IdentityFile" | awk '{print $2}' | sed "s|~|$HOME|")
        if [ -f "$SSH_KEY" ]; then
            print_success "SSH key exists at $SSH_KEY"
        else
            print_warning "SSH key not found at $SSH_KEY"
        fi
    else
        print_warning "No SSH config entry for $CONTAINER_NAME"
        echo "  You can add one manually or use: ssh user@$CONTAINER_IP"
    fi
else
    print_warning "No SSH config file found at ~/.ssh/config"
fi

# Test SSH connection (if container is running)
print_header "Testing SSH Connection"
if docker ps | grep -q "$CONTAINER_NAME"; then
    # Try SSH with config
    if grep -q "Host $CONTAINER_NAME" "$HOME/.ssh/config" 2>/dev/null; then
        if timeout 5 ssh -o BatchMode=yes -o ConnectTimeout=5 "$CONTAINER_NAME" "echo 'SSH works'" &>/dev/null; then
            print_success "SSH connection successful via hostname"
        else
            print_warning "SSH connection failed (might need password or key setup)"
            echo "  Try manually: ssh $CONTAINER_NAME"
        fi
    fi

    # Get username from docker-compose or Dockerfile
    USERNAME=$(docker exec "$CONTAINER_NAME" ls /home | head -1)
    if [ -n "$USERNAME" ]; then
        echo "  Container user: $USERNAME"
        echo "  Try: ssh $USERNAME@$CONTAINER_IP"
    fi
fi

# Check helper scripts
print_header "Checking Helper Scripts"
SCRIPTS=("install-ngrok" "setup-litellm" "setup-claude")
for script in "${SCRIPTS[@]}"; do
    if docker ps | grep -q "$CONTAINER_NAME"; then
        if docker exec "$CONTAINER_NAME" test -f "/usr/local/bin/$script"; then
            print_success "$script is available in container"
        else
            print_warning "$script not found in container"
        fi
    fi
done

# Check workspace directory
print_header "Checking Workspace"
if [ -d "workspace" ]; then
    print_success "Workspace directory exists"
    FILE_COUNT=$(find workspace -type f 2>/dev/null | wc -l)
    echo "  Files in workspace: $FILE_COUNT"
else
    print_warning "Workspace directory not found (will be created on first mount)"
fi

# Summary
print_header "Verification Summary"
if [ $ERRORS -eq 0 ]; then
    print_success "All checks passed! Container is ready to use."
    echo ""
    if docker ps | grep -q "$CONTAINER_NAME"; then
        if grep -q "Host $CONTAINER_NAME" "$HOME/.ssh/config" 2>/dev/null; then
            echo "Connect with: ${GREEN}ssh $CONTAINER_NAME${NC}"
        else
            USERNAME=$(docker exec "$CONTAINER_NAME" ls /home | head -1)
            echo "Connect with: ${GREEN}ssh $USERNAME@$CONTAINER_IP${NC}"
        fi
    fi
else
    print_error "Found $ERRORS error(s)"
    echo "Check the output above for details"
    exit 1
fi

echo ""

#!/bin/bash
#
# Verify Environment Variables
# Check what environment variables were actually used during build/runtime
#

clear
echo "========================================"
echo "  Environment Variable Verification"
echo "========================================"
echo ""

echo "🔍 Checking environment variables..."
echo ""

# Check what was set during build (if available)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "BUILD-TIME VARIABLES:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Hostname from build
if [ -f /etc/hostname ]; then
    BUILD_HOSTNAME=$(cat /etc/hostname)
    echo "HOSTNAME (from build):     $BUILD_HOSTNAME"
else
    echo "HOSTNAME (from build):     [not set]"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "RUNTIME VARIABLES:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Runtime hostname
RUNTIME_HOSTNAME=$(hostname)
echo "hostname (runtime):        $RUNTIME_HOSTNAME"

# Check what Docker passed as environment variable
if [ -n "$BUILD_HOSTNAME" ]; then
    echo "BUILD_HOSTNAME (env):      $BUILD_HOSTNAME"
else
    echo "BUILD_HOSTNAME (env):      [not set]"
fi

# Username
echo "USERNAME:                  $(whoami)"

# Timezone
echo "TIMEZONE:                  $(cat /etc/timezone 2>/dev/null || echo $TZ)"

# Working directory
echo "WORKDIR:                   $(pwd)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "DIAGNOSTIC:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if hostname matches
if [ -f /etc/hostname ]; then
    if [ "$BUILD_HOSTNAME" = "$RUNTIME_HOSTNAME" ]; then
        echo "✅ Hostname is consistent"
        echo "   Build and runtime match: $RUNTIME_HOSTNAME"
    else
        echo "⚠️  Hostname MISMATCH!"
        echo "   Build:   $BUILD_HOSTNAME"
        echo "   Runtime: $RUNTIME_HOSTNAME"
        if [ -n "$DOCKER_HOSTNAME" ]; then
            echo "   Expected: $DOCKER_HOSTNAME (from HOSTNAME env var)"
        fi
        echo ""
        echo "   This means Docker's hostname: setting overrode /etc/hostname"
        echo "   OR Portainer didn't apply the HOSTNAME environment variable"
    fi
else
    echo "⚠️  No /etc/hostname file found"
    echo "   Using runtime hostname: $RUNTIME_HOSTNAME"
fi

# Additional check - was CONTAINER_HOSTNAME env var passed to container?
if [ -n "$BUILD_HOSTNAME" ]; then
    echo ""
    echo "📋 Environment Variable Check:"
    if [ "$BUILD_HOSTNAME" = "$RUNTIME_HOSTNAME" ]; then
        echo "   ✅ CONTAINER_HOSTNAME env var matches runtime: $BUILD_HOSTNAME"
    else
        echo "   ❌ CONTAINER_HOSTNAME env var ($BUILD_HOSTNAME) ≠ runtime ($RUNTIME_HOSTNAME)"
        echo "   This indicates a Portainer bug with hostname: field"
        echo ""
        echo "   FIX: Set CONTAINER_HOSTNAME in env.rw.home (not HOSTNAME)"
        echo "   HOSTNAME is reserved by Portainer and doesn't work"
    fi
fi

echo ""

# Check if hostname is a container ID (random)
if [[ $RUNTIME_HOSTNAME =~ ^[0-9a-f]{12}$ ]]; then
    echo "❌ PROBLEM DETECTED!"
    echo ""
    echo "   Your hostname is a random container ID: $RUNTIME_HOSTNAME"
    echo ""
    echo "   This means the HOSTNAME environment variable was NOT set"
    echo "   when Portainer deployed the stack."
    echo ""
    echo "   SOLUTION:"
    echo "   1. In Portainer, specify env file: portainer.env"
    echo "   2. OR set environment variables manually in Portainer UI"
    echo "   3. Redeploy the stack"
    echo ""
elif [ "$RUNTIME_HOSTNAME" = "docker-dev" ] || [ "$RUNTIME_HOSTNAME" = "devuser" ]; then
    echo "⚠️  Using default hostname: $RUNTIME_HOSTNAME"
    echo ""
    echo "   You might want to customize this to something more unique."
    echo ""
else
    echo "✅ Custom hostname detected: $RUNTIME_HOSTNAME"
    echo ""
    echo "   Your HOSTNAME environment variable was successfully applied!"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "CONTAINER INFO:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# IP addresses
echo "IP Addresses:"
ip -4 addr show | grep inet | awk '{print "  " $2}' | grep -v "127.0.0.1"

echo ""

# Installed tools
echo "Installed Tools:"
for tool in claude litellm ngrok; do
    if command -v $tool &> /dev/null; then
        echo "  ✓ $tool"
    else
        echo "  ✗ $tool (not installed)"
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "For more info: ~/setup/container-info.sh"
echo ""

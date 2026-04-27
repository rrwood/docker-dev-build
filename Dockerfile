FROM alpine:latest

# Build arguments for customization
ARG USERNAME=devuser
ARG USER_PASSWORD=changeme123
ARG INSTALL_NGROK=false
ARG NGROK_AUTH_TOKEN=""
ARG GITHUB_REPO=https://github.com/rrwood/docker-dev-build.git
ARG GITHUB_BRANCH=main

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

# Clone repository to get setup scripts
RUN git clone --depth 1 --branch ${GITHUB_BRANCH} ${GITHUB_REPO} /tmp/setup-repo

# Setup SSH - disable root login, allow user login with password and keys
RUN ssh-keygen -A && \
    sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#AuthorizedKeysFile.*/AuthorizedKeysFile .ssh\/authorized_keys/' /etc/ssh/sshd_config

# Create user with provided credentials
RUN adduser -D -s /bin/bash ${USERNAME} && \
    echo "${USERNAME}:${USER_PASSWORD}" | chpasswd && \
    mkdir -p /home/${USERNAME}/.ssh && \
    chmod 700 /home/${USERNAME}/.ssh && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.ssh && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME}

# Copy helper scripts from cloned repo
RUN cp /tmp/setup-repo/scripts/install-ngrok.sh /usr/local/bin/install-ngrok && \
    cp /tmp/setup-repo/scripts/setup-litellm.sh /usr/local/bin/setup-litellm && \
    cp /tmp/setup-repo/scripts/setup-claude.sh /usr/local/bin/setup-claude && \
    chmod +x /usr/local/bin/install-ngrok /usr/local/bin/setup-litellm /usr/local/bin/setup-claude

# Install ngrok if requested
RUN if [ "$INSTALL_NGROK" = "true" ]; then \
        echo "Installing ngrok..." && \
        /usr/local/bin/install-ngrok ${NGROK_AUTH_TOKEN}; \
    fi

# Cleanup
RUN rm -rf /tmp/setup-repo

# Create working directory
WORKDIR /app
RUN chown ${USERNAME}:${USERNAME} /app

# Expose SSH port
EXPOSE 22

# Keep container running and start SSH
CMD ["/usr/sbin/sshd", "-D"]

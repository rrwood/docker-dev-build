FROM alpine:latest

# Build arguments for customization
ARG USERNAME=devuser
ARG USER_PASSWORD=changeme123
ARG CONTAINER_HOSTNAME=docker-dev
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

# Prepare setup scripts for user directory (includes both setup/ and scripts/ directories)
RUN mkdir -p /tmp/user-setup && \
    cp -r /tmp/setup-repo/setup/* /tmp/user-setup/ && \
    cp /tmp/setup-repo/scripts/install-ngrok.sh /tmp/user-setup/ && \
    cp /tmp/setup-repo/scripts/setup-litellm.sh /tmp/user-setup/ && \
    cp /tmp/setup-repo/scripts/setup-claude.sh /tmp/user-setup/ && \
    chmod +x /tmp/user-setup/*.sh

# Create user with provided credentials
RUN adduser -D -s /bin/bash ${USERNAME} && \
    echo "${USERNAME}:${USER_PASSWORD}" | chpasswd && \
    mkdir -p /home/${USERNAME}/.ssh && \
    chmod 700 /home/${USERNAME}/.ssh && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.ssh && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME}

# Copy setup scripts to user home directory
RUN mkdir -p /home/${USERNAME}/setup && \
    cp -r /tmp/user-setup/* /home/${USERNAME}/setup/ && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/setup

# Setup welcome message
RUN cp /home/${USERNAME}/setup/welcome-motd.sh /etc/profile.d/welcome.sh && \
    chmod +x /etc/profile.d/welcome.sh

# Create a first-login marker
RUN touch /home/${USERNAME}/.first_login && \
    chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.first_login

# Install ngrok if requested
RUN if [ "$INSTALL_NGROK" = "true" ]; then \
        echo "Installing ngrok..." && \
        /tmp/user-setup/install-ngrok.sh ${NGROK_AUTH_TOKEN}; \
    fi

# Cleanup
RUN rm -rf /tmp/setup-repo /tmp/user-setup

# Set hostname (done late to ensure no conflicts)
RUN echo "${CONTAINER_HOSTNAME}" > /etc/hostname

# Create working directory
WORKDIR /app
RUN chown ${USERNAME}:${USERNAME} /app

# Expose SSH port
EXPOSE 22

# Keep container running and start SSH
CMD ["/usr/sbin/sshd", "-D"]

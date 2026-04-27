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

# Install Claude CLI
RUN curl -fsSL https://claude.ai/install.sh | sh

# Setup SSH - disable root login, allow user login with password and keys
RUN ssh-keygen -A && \
    sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#AuthorizedKeysFile.*/AuthorizedKeysFile .ssh\/authorized_keys/' /etc/ssh/sshd_config

# Create a default user (you can customize this)
RUN adduser -D -s /bin/bash devuser && \
    echo 'devuser:changeme123' | chpasswd && \
    mkdir -p /home/devuser/.ssh && \
    chmod 700 /home/devuser/.ssh && \
    chown -R devuser:devuser /home/devuser/.ssh && \
    echo 'devuser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/devuser

# Copy helper scripts
COPY scripts/install-ngrok.sh /usr/local/bin/install-ngrok
COPY scripts/setup-litellm.sh /usr/local/bin/setup-litellm
RUN chmod +x /usr/local/bin/install-ngrok /usr/local/bin/setup-litellm

# Create working directory
WORKDIR /app
RUN chown devuser:devuser /app

# Expose SSH port
EXPOSE 22

# Keep container running and start SSH
CMD ["/usr/sbin/sshd", "-D"]
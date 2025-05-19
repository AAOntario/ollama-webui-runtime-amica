FROM nvidia/cuda:12.2.0-runtime-ubuntu22.04

# Install essential packages including openssh-server
RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3 \
    python3-pip \
    nginx \
    openssh-server \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Prepare SSH environment (persistent authorized_keys via /workspace/ssh/authorized_keys)
RUN mkdir -p /var/run/sshd /root/.ssh /workspace/ssh

# Optionally bind your authorized_keys via volume or build-time COPY
COPY ssh/authorized_keys /workspace/ssh/authorized_keys
RUN cp /workspace/ssh/authorized_keys /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys && \
    chmod 700 /root/.ssh && \
    chown -R root:root /root/.ssh

# Configure SSH to allow key-based login and disable password login
RUN sed -i 's/#AuthorizedKeysFile/AuthorizedKeysFile/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Clone and set up Open WebUI
RUN git clone https://github.com/open-webui/open-webui.git /opt/open-webui
WORKDIR /opt/open-webui
RUN pip install -r backend/requirements.txt

# Copy in runtime configuration and entrypoint
COPY docker-compose.yml /workspace/docker-compose.yml
COPY nginx.conf /workspace/nginx.conf
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Declare environment variable for Ollama models
ENV OLLAMA_MODELS=/workspace/models

# Document exposed ports (optional but recommended)
EXPOSE 80 8080 11434 4400

# Set entrypoint to start services
ENTRYPOINT ["/start.sh"]

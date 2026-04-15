#!/bin/bash
set -eux

# Environment variables
USERNAME=${1}
GITHUB_PAT=${2:-}
GITHUB_USERNAME=${3:-$USERNAME}

# Set non-interactive mode for apt-get
export DEBIAN_FRONTEND=noninteractive

# Install Docker
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
  sh /tmp/get-docker.sh
fi
usermod -aG docker "$USERNAME"

# Make docker socket accessible without requiring group reload (newgrp/logout)
mkdir -p /etc/systemd/system/docker.socket.d
cat <<EOF > /etc/systemd/system/docker.socket.d/override.conf
[Socket]
SocketMode=0666
EOF
systemctl daemon-reload
systemctl restart docker.socket || true

if [ -n "$GITHUB_PAT" ]; then
  until sg docker -c "docker info" > /dev/null 2>&1; do
    echo "Waiting for Docker daemon to start..."
    sleep 2
  done
  echo "Logging into ghcr.io..."
  echo "$GITHUB_PAT" | sg docker -c "docker login ghcr.io -u '$GITHUB_USERNAME' --password-stdin"
fi

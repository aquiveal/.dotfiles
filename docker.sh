#!/bin/bash
set -eux

# Environment variables
USERNAME=${1}

# Set non-interactive mode for apt-get
export DEBIAN_FRONTEND=noninteractive

# Install Docker
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
  sh /tmp/get-docker.sh
fi
usermod -aG docker "$USERNAME"
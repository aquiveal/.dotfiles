#!/bin/bash
set -eux

# Environment variables
TUNNEL_TOKEN=${1}

# Set non-interactive mode for apt-get
export DEBIAN_FRONTEND=noninteractive

# Install Cloudflared
if ! command -v cloudflared >/dev/null 2>&1; then
  curl -L --output /tmp/cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
  dpkg -i /tmp/cloudflared.deb
  rm /tmp/cloudflared.deb
fi

if [ ! -f /etc/systemd/system/cloudflared.service ]; then
  cloudflared service install $TUNNEL_TOKEN || true
fi
#!/bin/bash
set -eux

# Environment variables
USERNAME=${1}
HOME_DIR="/home/$USERNAME"
DATA_DIR="$HOME_DIR/.redis"

# Set non-interactive mode for apt-get
export DEBIAN_FRONTEND=noninteractive

# Install Redis tools (for redis-cli)
sudo apt update
sudo apt install redis-tools -y

# Check if Docker is installed
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed. Running local docker.sh..."
  if [ -f "./autostart/docker.sh" ]; then
    sudo bash ./autostart/docker.sh "$USERNAME"
  else
    curl -fsSL "https://raw.githubusercontent.com/aquiveal/.dotfiles/refs/heads/main/autostart/docker.sh" -o /tmp/docker.sh
    sudo bash /tmp/docker.sh "$USERNAME"
  fi
fi

# Create the data directory if it doesn't exist
mkdir -p "$DATA_DIR"

# Run the Redis Docker container
docker run -d \
  --name redis \
  --restart unless-stopped \
  -v "$DATA_DIR":/data \
  -p 6379:6379 \
  redis:latest || true

# Wait for Redis to become ready
echo "Waiting for Redis to be ready..."
until docker exec redis redis-cli ping | grep -q PONG; do
  sleep 1
done

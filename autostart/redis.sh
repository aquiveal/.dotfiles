#!/bin/bash
set -eux

# Environment variables
USERNAME=${1}
HOME_DIR="/home/$USERNAME"
DATA_DIR="$HOME_DIR/.redis"

# Set non-interactive mode for apt-get
export DEBIAN_FRONTEND=noninteractive

# Install Redis tools and server

while pgrep -x apt >/dev/null || pgrep -x apt-get >/dev/null || pgrep -x dpkg >/dev/null; do echo "Waiting for apt/dpkg to finish..."; sleep 1; done

sudo apt-get -qq update
sudo apt-get install -y -qq redis-tools redis-server < /dev/null

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
CONTAINER_NAME="redis-autostart"
docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  -v "$DATA_DIR":/data \
  -p 6379:6379 \
  redis:latest || true

# Wait for Redis to become ready
echo "Waiting for Redis to be ready..."
MAX_RETRIES=30
RETRY_COUNT=0
until docker exec "$CONTAINER_NAME" redis-cli ping | grep -q PONG; do
  sleep 1
  RETRY_COUNT=$((RETRY_COUNT+1))
  if [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
    echo "Redis failed to start."
    exit 1
  fi
done

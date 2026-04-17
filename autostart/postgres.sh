#!/bin/bash

# Environment variables
USERNAME=${1}

# Set non-interactive mode for apt-get
export DEBIAN_FRONTEND=noninteractive

# Install PostgreSQL client

while pgrep -x apt >/dev/null || pgrep -x apt-get >/dev/null || pgrep -x dpkg >/dev/null; do echo "Waiting for apt/dpkg to finish..."; sleep 1; done

sudo apt update
sudo apt install postgresql-client -y

# Check if Docker is installed, pull and install if not
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed. Downloading and running docker.sh..."
  curl -fsSL "https://raw.githubusercontent.com/aquiveal/.dotfiles/refs/heads/main/autostart/docker.sh" -o /tmp/docker.sh
  sudo bash /tmp/docker.sh "$USERNAME"
fi

# Define the data directory using the current user's home directory
DATA_DIR="/home/$USERNAME/.postgresql"

# Create the data directory if it doesn't exist
mkdir -p "$DATA_DIR"

# Run the PostgreSQL Docker container
docker run -d \
  --name postgres \
  --restart unless-stopped \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=postgres \
  -v "$DATA_DIR":/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:17-alpine || true

# Wait for PostgreSQL to become ready
echo "Waiting for PostgreSQL to be ready..."
until docker exec postgres pg_isready -U postgres > /dev/null 2>&1; do
  sleep 1
done

# Create additional databases if provided as arguments
for DB_NAME in "${@:2}"; do
  echo "Checking/Creating database: $DB_NAME"
  docker exec postgres psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1 || \
    docker exec postgres psql -U postgres -c "CREATE DATABASE \"$DB_NAME\";"
done

#!/bin/bash
set -eux

# Environment variables
USERNAME=${1}
HOME_DIR="/home/$USERNAME"

# Install Hatchet and start the server as the specified user
sudo su - "$USERNAME" -c "
  # Install Hatchet CLI if not present
  if ! command -v hatchet >/dev/null 2>&1; then
    echo \"Installing Hatchet CLI...\"
    curl -fsSL https://install.hatchet.run/install.sh | bash
  fi

  # Ensure Hatchet is available in PATH for current session
  export PATH=\$PATH:\$HOME/.local/bin

  # Wait for Docker to be accessible
  until docker info > /dev/null 2>&1; do
    echo \"Waiting for Docker daemon to start...\"
    sleep 2
  done

  # Create persistent directories for hatchet
  mkdir -p \$HOME/.hatchet/config
  mkdir -p \$HOME/.hatchet/postgres
  
  # Create named volumes bound to the persistent directories if they don't exist
  if ! docker volume inspect hatchet-cli_hatchet_config > /dev/null 2>&1; then
    docker volume create --driver local --opt type=none --opt device=\$HOME/.hatchet/config --opt o=bind hatchet-cli_hatchet_config
  fi
  if ! docker volume inspect hatchet-cli_postgres_data > /dev/null 2>&1; then
    docker volume create --driver local --opt type=none --opt device=\$HOME/.hatchet/postgres --opt o=bind hatchet-cli_postgres_data
  fi

  # Start the local Hatchet development server
  echo \"Starting Hatchet local server...\"
  hatchet server start
"

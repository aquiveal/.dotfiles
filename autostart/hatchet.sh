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

  # Start the local Hatchet development server
  echo \"Starting Hatchet local server...\"
  hatchet server start
"

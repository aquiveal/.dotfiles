#!/bin/bash
set -eux

USERNAME=${1}
HOME_DIR="/home/$USERNAME"
PYTHON_VERSION=${2:-"3.14"}

export DEBIAN_FRONTEND=noninteractive

sudo su - "$USERNAME" -c "
  if ! command -v uv >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
  fi
  
  # Ensure uv is accessible in PATH
  source \"$HOME_DIR/.local/bin/env\" || export PATH=\"$HOME_DIR/.local/bin:\$PATH\"
  
  if ! uv python list | grep -q \"$PYTHON_VERSION\"; then
    uv python install $PYTHON_VERSION --default
  fi
  
  curl -sSL https://pdm-project.org/install.sh | bash
"
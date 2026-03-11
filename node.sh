#!/bin/bash
set -eux

# Environment variables
USERNAME=${1}
HOME_DIR="/home/$USERNAME"
NVM_VERSION=${2:-"0.40.4"}
NODE_VERSION=${2:-"24.14.0"}

# Set non-interactive mode for apt-get
export DEBIAN_FRONTEND=noninteractive

# Install Node.js
su - "$USERNAME" -c '
  if [ ! -d "$HOME_DIR/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v$NVM_VERSION/install.sh | bash
  fi
  export NVM_DIR="$HOME_DIR/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  
  if ! nvm ls $NODE_VERSION >/dev/null 2>&1; then
    nvm install v$NODE_VERSION
    nvm alias default v$NODE_VERSION
  fi
  
  if ! command -v yarn >/dev/null 2>&1; then
    npm install -g yarn
  fi
  
  if ! command -v pnpm >/dev/null 2>&1; then
    curl -fsSL https://get.pnpm.io/install.sh | sh -
  fi
'
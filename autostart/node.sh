#!/bin/bash
set -eux

# Environment variables
USERNAME=${1}
HOME_DIR="/home/$USERNAME"
NVM_VERSION=${2:-"0.40.4"}
NODE_VERSION=${3:-"24.14.0"}

# Set non-interactive mode for apt-get
export DEBIAN_FRONTEND=noninteractive

# Ensure required dependencies for pnpm are installed
while pgrep -x apt >/dev/null || pgrep -x apt-get >/dev/null || pgrep -x dpkg >/dev/null; do echo "Waiting for apt/dpkg to finish..."; sleep 1; done
sudo apt-get -qq update
sudo apt-get install -y -qq libatomic1 < /dev/null

# Install Node.js
sudo su - "$USERNAME" -c "
  if [ ! -d \"\$HOME/.nvm\" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v$NVM_VERSION/install.sh | bash
  fi
  export NVM_DIR=\"\$HOME/.nvm\"
  [ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\"
  
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
"
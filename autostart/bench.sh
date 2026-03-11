#!/bin/bash
set -eux

# Environment variables
USERNAME=${1}
HOME_DIR="/home/$USERNAME"
MYSQL_DATA_DIR="$HOME_DIR/.mysql"

# Set non-interactive mode for apt-get
export DEBIAN_FRONTEND=noninteractive

echo ">>> Starting Frappe/Bench Stack Installation..."

# Helper function to run a script locally if it exists, or via URL otherwise
run_script() {
  local script_name=$1
  shift
  local url="https://raw.githubusercontent.com/aquiveal/.dotfiles/refs/heads/main/autostart/${script_name}"
  
  if [ -f "./${script_name}" ]; then
    echo "Running local ${script_name}..."
    bash "./${script_name}" "$@"
  else
    echo "Downloading and running ${script_name} from ${url}..."
    curl -fsSL "${url}" | bash -s -- "$@"
  fi
}

# 1. System-level dependencies (Git, wkhtmltopdf, etc.)
apt-get update
apt-get install -y git pkg-config xvfb libfontconfig1 fontconfig xfonts-75dpi cron rsync wget curl

## wkhtmltopdf
if ! command -v wkhtmltopdf >/dev/null 2>&1; then
  echo "Installing wkhtmltopdf..."
  wget -q https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb -O /tmp/wkhtmltox.deb
  apt-get install -y /tmp/wkhtmltox.deb
  rm /tmp/wkhtmltox.deb
fi

# 2. Redis setup
run_script redis.sh

# 3. MariaDB setup
run_script mariadb.sh "$USERNAME"

# 4. User-level setup (Node, Python)
run_script node.sh "$USERNAME" 0.40.4 24.14.0
run_script python.sh "$USERNAME" 3.14

# 5. Frappe Bench setup
sudo su - "$USERNAME" -c '
  set -eux
  
  # Ensure uv is accessible in PATH for this session
  source $HOME/.local/bin/env || export PATH="$HOME/.local/bin:$PATH"

  # --- C. FRAPPE BENCH ---
  if ! command -v bench >/dev/null 2>&1; then
    echo "Installing Frappe Bench CLI..."
    uv tool install frappe-bench
  fi

  # Initialize the Bench instance
  mkdir -p "$HOME/frappe"
  cd "$HOME/frappe"
  
  if [ ! -d "my-bench" ]; then
    echo "Initializing new Frappe Bench instance..."
    bench init my-bench
  else
    echo "Bench my-bench already initialized. Skipping."
  fi
'

echo ">>> Bench Setup Complete!"

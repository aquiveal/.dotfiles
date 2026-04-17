#!/bin/bash
set -eux

# Environment variables
USERNAME=${1}
HOME_DIR="/home/$USERNAME"
DATA_DIR="$HOME_DIR/.mysql"

# Set non-interactive mode for apt-get
export DEBIAN_FRONTEND=noninteractive

# Install MariaDB client tools

while pgrep -x apt >/dev/null || pgrep -x apt-get >/dev/null || pgrep -x dpkg >/dev/null; do echo "Waiting for apt/dpkg to finish..."; sleep 1; done

sudo apt update
sudo apt install mariadb-client -y

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

# Setup Persistence on User's Disk
mkdir -p "$DATA_DIR"

# Run the MariaDB Docker container
docker run -d \
  --name mariadb \
  --restart unless-stopped \
  -e MARIADB_ROOT_PASSWORD=root \
  -v "$DATA_DIR":/var/lib/mysql \
  -p 3306:3306 \
  mariadb:latest || true

# Wait for MariaDB to become ready
echo "Waiting for MariaDB to be ready..."
until docker exec mariadb mariadb-admin ping -h localhost -uroot -proot --silent >/dev/null 2>&1; do
  sleep 1
done

# Headless Secure Installation cleanup and remote access setup
docker exec mariadb mariadb -uroot -proot -e "CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY 'root';" || true
docker exec mariadb mariadb -uroot -proot -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;" || true
docker exec mariadb mariadb -uroot -proot -e "UPDATE IGNORE mysql.global_priv SET Host='%' WHERE Host='localhost';" || true
docker exec mariadb mariadb -uroot -proot -e "DELETE FROM mysql.global_priv WHERE Host='localhost';" || true
docker exec mariadb mariadb -uroot -proot -e "UPDATE IGNORE mysql.db SET Host='%' WHERE Host='localhost';" || true
docker exec mariadb mariadb -uroot -proot -e "DELETE FROM mysql.db WHERE Host='localhost';" || true
docker exec mariadb mariadb -uroot -proot -e "DELETE FROM mysql.user WHERE User='';" || true
docker exec mariadb mariadb -uroot -proot -e "DROP DATABASE IF EXISTS test;" || true
docker exec mariadb mariadb -uroot -proot -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';" || true
docker exec mariadb mariadb -uroot -proot -e "FLUSH PRIVILEGES;" || true

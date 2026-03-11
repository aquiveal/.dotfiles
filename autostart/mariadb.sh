#!/bin/bash
set -eux
USERNAME=${1}
HOME_DIR="/home/$USERNAME"
MYSQL_DATA_DIR="$HOME_DIR/.mysql"

export DEBIAN_FRONTEND=noninteractive

# 1. Install MariaDB
if ! dpkg -l | grep -q "mariadb-server"; then
  apt-get install -y mariadb-server mariadb-client libmariadb-dev libmariadb-dev-compat libmariadb-dev default-libmysqlclient-dev
fi

# 2. Setup Persistence on User's Disk
systemctl stop mariadb || true
mkdir -p "$MYSQL_DATA_DIR"
chown -R mysql:mysql "$MYSQL_DATA_DIR"

if ! mountpoint -q /var/lib/mysql; then
  ## Tell AppArmor to allow MySQL to access the new location on the persistent disk
  if ! grep -q "$MYSQL_DATA_DIR" /etc/apparmor.d/tunables/alias; then
    echo "alias /var/lib/mysql/ -> $MYSQL_DATA_DIR/," >> /etc/apparmor.d/tunables/alias
    systemctl restart apparmor || true
  fi

  ## If target dir is empty, sync defaults to it
  if [ -z "$(ls -A "$MYSQL_DATA_DIR")" ]; then
    rsync -a /var/lib/mysql/ "$MYSQL_DATA_DIR/"
  fi
  
  mount --bind "$MYSQL_DATA_DIR" /var/lib/mysql
fi

systemctl start mariadb || true
systemctl enable mariadb || true

# 3. Headless Secure Installation
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED VIA unix_socket;" || true
mysql -e "DELETE FROM mysql.user WHERE User='';" || true
mysql -e "DROP DATABASE IF EXISTS test;" || true
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';" || true
mysql -e "FLUSH PRIVILEGES;" || true
#!/bin/bash
set -eux

# Environment variables
USERNAME=${1}
HOME_DIR="/home/$USERNAME"
DISK_DEVICE_ID="google-persistent-home"
DEVICE_PATH="/dev/disk/by-id/$DISK_DEVICE_ID"

# Set non-interactive mode for apt-get
export DEBIAN_FRONTEND=noninteractive

# 1. Ensure user exists
if ! id -u "$USERNAME" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$USERNAME"
  echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/coder-user
fi

# 2. Format and mount persistent disk if present
if [ -b "$DEVICE_PATH" ]; then
  if ! blkid "$DEVICE_PATH"; then
    mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard "$DEVICE_PATH"
    mkdir -p /mnt/tmp_home
    mount "$DEVICE_PATH" /mnt/tmp_home
    rsync -a "$HOME_DIR/" /mnt/tmp_home/
    umount /mnt/tmp_home
  fi
  
  if ! mountpoint -q "$HOME_DIR"; then
    mount -o discard,defaults "$DEVICE_PATH" "$HOME_DIR"
    chown -R "$USERNAME:$USERNAME" "$HOME_DIR"
  fi
fi

apt-get update
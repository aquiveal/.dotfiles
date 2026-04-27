#!/bin/bash
set -euo pipefail

# Check for required parameters
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <nfs_host> <share_path> <mount_point>"
    echo "Example: $0 filestore.silo.asia-south1.prod.aurumor.com /share /mnt/my-share"
    exit 1
fi

NFS_HOST=$1
SHARE_PATH=$2
MOUNT_POINT=$3

# Ensure the script is run with sudo if needed for mounting
if [[ $EUID -ne 0 ]]; then
   echo "This script needs to be run as root or with sudo for mounting."
   exec sudo bash "$0" "$@"
   exit $?
fi

echo "Mounting $NFS_HOST:$SHARE_PATH to $MOUNT_POINT..."

# Set non-interactive mode for apt-get
export DEBIAN_FRONTEND=noninteractive

# Install nfs-common if not present
if ! command -v mount.nfs >/dev/null 2>&1; then
    echo "Installing nfs-common..."
    while pgrep -x apt >/dev/null || pgrep -x apt-get >/dev/null || pgrep -x dpkg >/dev/null; do echo "Waiting for apt/dpkg to finish..."; sleep 1; done
    apt-get update -qq
    apt-get install -y -qq nfs-common < /dev/null
fi

# Create mount point
mkdir -p "$MOUNT_POINT"

# Mount the share
# Using -o nolock as it is often required for cloud filestores if not using a sidecar
mount -t nfs "$NFS_HOST:$SHARE_PATH" "$MOUNT_POINT"

echo "NFS share mounted successfully at $MOUNT_POINT"
df -h "$MOUNT_POINT"

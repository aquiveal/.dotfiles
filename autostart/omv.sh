#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "Not running as root, attempting to escalate privileges..."
   exec sudo -H "$0" "$@"
   exit $?
fi

# Check if OpenMediaVault is already installed
if dpkg -l | grep -q "openmediavault"; then
    echo "OpenMediaVault is already installed. Exiting to prevent redundant installation."
    exit 0
fi

echo "Starting OpenMediaVault 8 (Synchrony) Installation on Debian 13"

# 1. Install and configure systemd-resolved temporarily
echo "[1/6] Installing and configuring systemd-resolved..."
apt-get update
apt-get install --yes systemd-resolved psmisc iproute2

systemctl enable --now systemd-resolved.service
systemctl restart systemd-resolved.service

# Auto-detect the default network interface to set temporary DNS
INTERFACE=$(ip route show default | awk '/default/ {print $5}' | head -n 1)
DNS_SERVER_IP="8.8.8.8" # Using a reliable public DNS temporarily

if [ -n "$INTERFACE" ]; then
    echo "Setting temporary DNS ($DNS_SERVER_IP) on interface: $INTERFACE"
    # Kill dhcp client if it exists to prevent interference (as per docs)
    killall dhcpcd 2>/dev/null || true
    resolvectl dns "$INTERFACE" "$DNS_SERVER_IP"
else
    echo "Warning: Could not detect default network interface. Skipping resolvectl step."
fi

# 2. Install the OMV keyring manually
echo "[2/6] Installing OpenMediaVault keyring..."
apt-get install --yes gnupg wget
wget --quiet --output-document=- https://packages.openmediavault.org/public/archive.key | gpg --dearmor --yes --output "/usr/share/keyrings/openmediavault-archive-keyring.gpg"

# 3. Add the OMV 8 (synchrony) package repositories
echo "[3/6] Adding OpenMediaVault 8 (synchrony) repositories..."
cat <<EOF > /etc/apt/sources.list.d/openmediavault.list
deb [signed-by=/usr/share/keyrings/openmediavault-archive-keyring.gpg] https://packages.openmediavault.org/public synchrony main
# deb [signed-by=/usr/share/keyrings/openmediavault-archive-keyring.gpg] https://downloads.sourceforge.net/project/openmediavault/packages synchrony main

## Uncomment the following line to add software from the proposed repository.
# deb [signed-by=/usr/share/keyrings/openmediavault-archive-keyring.gpg] https://packages.openmediavault.org/public synchrony-proposed main
# deb [signed-by=/usr/share/keyrings/openmediavault-archive-keyring.gpg] https://downloads.sourceforge.net/project/openmediavault/packages synchrony-proposed main

## This software is not part of OpenMediaVault, but is offered by third-party
## developers as a service to OpenMediaVault users.
# deb [signed-by=/usr/share/keyrings/openmediavault-archive-keyring.gpg] https://packages.openmediavault.org/public synchrony partner
# deb [signed-by=/usr/share/keyrings/openmediavault-archive-keyring.gpg] https://downloads.sourceforge.net/project/openmediavault/packages synchrony partner
EOF

# 4. Install the OMV package
echo "[4/6] Installing OpenMediaVault packages..."
export LANG=C.UTF-8
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none

apt-get update
apt-get --yes --auto-remove --show-upgraded \
    --allow-downgrades --allow-change-held-packages \
    --no-install-recommends \
    --option DPkg::Options::="--force-confdef" \
    --option DPkg::Options::="--force-confold" \
    install openmediavault

# 5. Populate the OMV database
echo "[5/6] Populating the OpenMediaVault database..."
omv-confdbadm populate

# 6. Re-deploy network configuration
echo "[6/6] Re-deploying network configuration via salt..."
echo "WARNING: Your IP address may change during this step, and your SSH session might drop!"
# We use '|| true' so the script doesn't abort if the SSH connection drops during network restart
omv-salt deploy run systemd-networkd || true

echo "OpenMediaVault 8 (Synchrony) installation is complete!"
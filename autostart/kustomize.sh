#!/bin/bash

# Ensure non-interactive execution for startup scripts
export DEBIAN_FRONTEND=noninteractive

# Use a temporary directory to avoid leaving files behind
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR" || exit 1

# Run the official installation script to download kustomize
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash

# Move kustomize to the system PATH and make it executable
sudo mv kustomize /usr/local/bin/
sudo chmod +x /usr/local/bin/kustomize

# Clean up temporary files
cd - > /dev/null || true
rm -rf "$TMP_DIR"

#!/bin/bash

# Ensure non-interactive execution for startup scripts
export DEBIAN_FRONTEND=noninteractive

# Use a temporary directory for downloading
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR" || exit 1

# Download the latest kubectl release binary
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Install kubectl system-wide
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Clean up temporary files
cd - > /dev/null || true
rm -rf "$TMP_DIR"

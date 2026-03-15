#!/bin/bash

# Ensure non-interactive execution for startup scripts
export DEBIAN_FRONTEND=noninteractive

# Install required dependencies
sudo apt-get install curl gpg apt-transport-https --yes

# Add Helm repository and GPG key
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

# Update package lists and install Helm
sudo apt-get update
sudo apt-get install helm --yes

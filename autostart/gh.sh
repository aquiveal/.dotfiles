#!/usr/bin/env bash
set -euxo pipefail

GITHUB_PAT=${1:-}

# 1. Install curl if you don't have it
type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y)

# 2. Add the official GitHub CLI GPG key
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
&& sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg

# 3. Add the repository to your sources list
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# 4. Update and install
sudo apt update
sudo apt install gh -y

# 5. Authenticate GitHub CLI
if gh auth status >/dev/null 2>&1; then
    echo "GitHub CLI is already authenticated."
else
    if [ -n "$GITHUB_PAT" ]; then
        echo "Authenticating using GITHUB_PAT..."
        set +x
        echo "$GITHUB_PAT" | gh auth login --with-token
        set -x
        gh config set -h github.com git_protocol https
        echo "Authentication complete."
    else
        echo "GITHUB_PAT is not set. Launching interactive login..."
        gh auth login
    fi
fi

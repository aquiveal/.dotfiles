# .dotfiles

This repository contains configuration files and initialization scripts for setting up a development environment, specifically tailored for [Coder](https://coder.com/) workspaces.

## Repository Structure

- **`autostart/`**: A collection of bash scripts used to install and configure various tools and services within the Linux workspace environment.
  - `coder-init.sh`: Initializes the Coder workspace, sets up the user, and mounts a persistent disk.
  - `docker.sh`: Installs Docker and configures it for the user, with optional GitHub Container Registry login.
  - `node.sh`: Installs Node.js via NVM, along with Yarn and pnpm.
  - `python.sh`: Installs Python using `uv` and sets up `pdm`.
  - `tailscale.sh`: Installs and configures Tailscale for secure networking.
  - *Other scripts*: Includes setup for Kubernetes tools (`kubectl`, `helm`, `kustomize`), databases (`postgres`, `mariadb`, `redis`), and various utilities (`gh`, `cloudflared`, etc.).
- **`coder.bat`**: A Windows batch script that establishes a Coder SSH connection while launching a background synchronization script.
- **`gcloud.bat`**: A Windows batch script designed to sync local Google Cloud credentials to the remote Coder workspace. It verifies local tokens, polls for SSH readiness, and securely copies the credentials.
- **`config`**: An SSH configuration file containing host entries for GitHub and Coder, including specific overrides for Mutagen synchronization.
- **`mutagen.yml.lock`**: Lock file for [Mutagen](https://mutagen.io/), used for fast file synchronization.

## Usage

These scripts are designed to be executed during the initialization phase of a Coder workspace or run manually to provision a new development environment with the necessary tools and configurations.

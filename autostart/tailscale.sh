#!/usr/bin/env bash
set -euxo pipefail

# Require TS_AUTHKEY as first argument
TS_AUTHKEY="${1:-}"

if [[ -z "${TS_AUTHKEY}" ]]; then
  echo "Usage: $0 <TS_AUTHKEY>" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi

if ! sudo tailscale status >/dev/null 2>&1; then
  sudo tailscale up --auth-key="${TS_AUTHKEY}"
fi
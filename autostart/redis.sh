#!/bin/bash
set -eux

export DEBIAN_FRONTEND=noninteractive

# Install Redis
if ! dpkg -l | grep -q "redis-server"; then
  apt-get install -y redis-server
fi

systemctl enable redis-server || true
systemctl start redis-server || true
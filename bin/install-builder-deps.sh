#!/usr/bin/env bash

set -euo pipefail

apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates \
  git \
  openssh-client \
  unzip
rm -rf /var/lib/apt/lists/*

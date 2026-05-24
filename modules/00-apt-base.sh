#!/usr/bin/env bash
# 00-apt-base.sh — apt refresh and base toolchain.

set -euo pipefail
IFS=$'\n\t'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$REPO_ROOT/lib/common.sh"

apt_refresh_if_stale
ensure_apt_pkg \
  curl \
  git \
  build-essential \
  ca-certificates \
  software-properties-common \
  unzip

#!/usr/bin/env bash
# 80-aws.sh — AWS CLI v2 from Amazon's official installer, if missing.
# It lands in /usr/local/aws-cli; the download is unpacked in a temp dir
# and removed. Amazon's installer takes --update for upgrades.

set -euo pipefail
IFS=$'\n\t'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$REPO_ROOT/lib/common.sh"

if have_cmd aws; then
  log "aws already installed: $(aws --version 2>&1 | cut -d' ' -f1)"
  exit 0
fi

ensure_apt_pkg curl unzip

arch="$(uname -m)"
case "$arch" in
  x86_64 | aarch64) ;;
  *) log "no AWS CLI v2 build for $arch"; exit 1 ;;
esac

log "installing AWS CLI v2 ($arch)"
if [[ "${DRY_RUN:-0}" == "1" ]]; then exit 0; fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${arch}.zip" -o "$tmp/awscliv2.zip"
unzip -q "$tmp/awscliv2.zip" -d "$tmp"
sudo "$tmp/aws/install"
log "installed: $(aws --version 2>&1 | cut -d' ' -f1)"

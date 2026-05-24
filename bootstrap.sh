#!/usr/bin/env bash
# bootstrap.sh — the only file users curl-pipe to bash.
# Clones the dotfiles repo (if absent) and execs install.sh with passed args.
#
# Usage:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/<user>/dotfiles/main/bootstrap.sh)"
#
# REPO_URL must point at the published repo. Edit this constant after first push.

set -euo pipefail
IFS=$'\n\t'

REPO_URL="https://github.com/<user>/dotfiles.git"
DEST="${DOTFILES_DEST:-$HOME/ws/dotfiles}"

log() { printf '[bootstrap] %s\n' "$*"; }

if ! command -v git >/dev/null 2>&1; then
  log "installing git"
  sudo apt-get update -y
  sudo apt-get install -y git
fi

if [[ ! -d "$DEST/.git" ]]; then
  log "cloning $REPO_URL -> $DEST"
  mkdir -p "$(dirname "$DEST")"
  git clone "$REPO_URL" "$DEST"
else
  log "repo already at $DEST; pulling"
  git -C "$DEST" pull --ff-only || log "git pull failed; continuing with current checkout"
fi

exec "$DEST/install.sh" "$@"

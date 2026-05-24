#!/usr/bin/env bash
# 30-zsh.sh — install zsh, oh-my-zsh (without auto-chsh), then set zsh as login shell.

set -euo pipefail
IFS=$'\n\t'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$REPO_ROOT/lib/common.sh"

ensure_apt_pkg zsh

OMZ_DIR="$HOME/.oh-my-zsh"
if [[ -d "$OMZ_DIR" ]]; then
  log "oh-my-zsh already installed at $OMZ_DIR"
else
  log "installing oh-my-zsh"
  if [[ "${DRY_RUN:-0}" != "1" ]]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
fi

ZSH_BIN="$(command -v zsh || true)"
if [[ -z "$ZSH_BIN" ]]; then
  log "zsh missing after install; skipping chsh"
  exit 0
fi

current_shell="$(getent passwd "$USER" | cut -d: -f7)"
if [[ "$current_shell" == "$ZSH_BIN" ]]; then
  log "$USER login shell already $ZSH_BIN"
else
  log "changing login shell for $USER -> $ZSH_BIN"
  if [[ "${DRY_RUN:-0}" != "1" ]]; then
    chsh -s "$ZSH_BIN" "$USER"
  fi
fi

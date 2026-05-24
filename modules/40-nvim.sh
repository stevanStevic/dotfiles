#!/usr/bin/env bash
# 40-nvim.sh — ensure neovim >= 0.11; install via official PPA if needed.

set -euo pipefail
IFS=$'\n\t'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$REPO_ROOT/lib/common.sh"

MIN_MAJOR=0
MIN_MINOR=11

needs_install=1
if have_cmd nvim; then
  ver="$(nvim --version | head -1 | awk '{print $2}' | sed 's/^v//')"
  major="${ver%%.*}"
  rest="${ver#*.}"
  minor="${rest%%.*}"
  if [[ "$major" -gt "$MIN_MAJOR" ]] \
     || { [[ "$major" -eq "$MIN_MAJOR" ]] && [[ "$minor" -ge "$MIN_MINOR" ]]; }; then
    log "neovim $ver meets >= ${MIN_MAJOR}.${MIN_MINOR}"
    needs_install=0
  else
    log "neovim $ver too old (need >= ${MIN_MAJOR}.${MIN_MINOR}); reinstalling"
  fi
fi

if [[ "$needs_install" == "1" ]]; then
  PPA_FILE_GLOB='/etc/apt/sources.list.d/neovim-ppa-*stable*.list'
  if ! compgen -G "$PPA_FILE_GLOB" >/dev/null; then
    log "adding ppa:neovim-ppa/stable"
    if [[ "${DRY_RUN:-0}" != "1" ]]; then
      sudo add-apt-repository -y ppa:neovim-ppa/stable
      sudo apt-get update -y
    fi
  else
    log "neovim PPA already configured"
  fi
  ensure_apt_pkg neovim
fi

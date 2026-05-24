#!/usr/bin/env bash
# 60-fonts.sh — install Nerd Fonts (JetBrainsMono + Meslo) for the current user.

set -euo pipefail
IFS=$'\n\t'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$REPO_ROOT/lib/common.sh"

ensure_apt_pkg fontconfig

FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

# install_nerd_font <zip-name-stem> <fc-list grep>
install_nerd_font() {
  local zip_stem="$1" grep_str="$2"
  local subdir="$FONT_DIR/$zip_stem-NerdFont"
  if [[ -d "$subdir" ]] && [[ -n "$(find "$subdir" -maxdepth 1 -name '*.ttf' -print -quit)" ]]; then
    log "$grep_str already installed"
    return 0
  fi
  if fc-list 2>/dev/null | grep -qi "$grep_str"; then
    log "$grep_str already installed (via fc-list)"
    return 0
  fi
  log "installing $grep_str"
  if [[ "${DRY_RUN:-0}" == "1" ]]; then return 0; fi

  mkdir -p "$subdir"
  local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${zip_stem}.zip"
  local tmpzip
  tmpzip="$(mktemp --suffix=.zip)"
  curl -fsSL -o "$tmpzip" "$url"
  unzip -oq "$tmpzip" -d "$subdir"
  rm -f "$tmpzip"
}

install_nerd_font JetBrainsMono "JetBrainsMono Nerd Font"
install_nerd_font Meslo         "MesloLGS Nerd Font"

log "running fc-cache -f"
if [[ "${DRY_RUN:-0}" != "1" ]]; then
  fc-cache -f
fi

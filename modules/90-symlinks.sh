#!/usr/bin/env bash
# 90-symlinks.sh — link dotfiles/ entries into $HOME.

set -euo pipefail
IFS=$'\n\t'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$REPO_ROOT/lib/common.sh"

DOTFILES_DIR="$REPO_ROOT/dotfiles"

# is_empty <path>: true if a regular file is empty, or a dir contains
# nothing but .keep markers and empty files.
is_empty() {
  local p="$1"
  if [[ -f "$p" ]]; then
    [[ ! -s "$p" ]]
    return
  fi
  if [[ -d "$p" ]]; then
    local found
    found="$(find "$p" -mindepth 1 -type f -not -name '.keep' ! -empty -print -quit)"
    [[ -z "$found" ]]
    return
  fi
  return 1
}

# Top-level files in dotfiles/ link directly into $HOME
shopt -s dotglob nullglob
for entry in "$DOTFILES_DIR"/*; do
  base="$(basename "$entry")"
  case "$base" in
    .|..|config) continue ;;
  esac
  if is_empty "$entry"; then
    log "skip empty: $base"
    continue
  fi
  ensure_symlink "$entry" "$HOME/$base"
done
shopt -u dotglob nullglob

# dotfiles/config/<x> -> ~/.config/<x>
if [[ -d "$DOTFILES_DIR/config" ]]; then
  mkdir -p "$HOME/.config"
  for sub in "$DOTFILES_DIR/config"/*; do
    [[ -e "$sub" ]] || continue
    name="$(basename "$sub")"
    if is_empty "$sub"; then
      log "skip empty: config/$name"
      continue
    fi
    ensure_symlink "$sub" "$HOME/.config/$name"
  done
fi

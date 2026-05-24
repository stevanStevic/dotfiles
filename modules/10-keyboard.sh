#!/usr/bin/env bash
# 10-keyboard.sh — remap Caps Lock to Ctrl via /etc/default/keyboard.

set -euo pipefail
IFS=$'\n\t'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$REPO_ROOT/lib/common.sh"

KB_FILE=/etc/default/keyboard
OPT='caps:ctrl_modifier'

if [[ ! -f "$KB_FILE" ]]; then
  log "$KB_FILE not found; skipping (non-Debian system?)"
  exit 0
fi

if grep -qE "^XKBOPTIONS=.*\\b${OPT}\\b" "$KB_FILE"; then
  log "$OPT already present in $KB_FILE"
  exit 0
fi

# Take a one-time backup
if ! compgen -G "${KB_FILE}.bak-*" >/dev/null; then
  backup="${KB_FILE}.bak-$(_utc_ts)"
  log "backing up $KB_FILE -> $backup"
  if [[ "${DRY_RUN:-0}" != "1" ]]; then
    sudo cp -p "$KB_FILE" "$backup"
  fi
fi

# Decide which edit to apply
if grep -qE '^XKBOPTIONS=' "$KB_FILE"; then
  if grep -qE '^XKBOPTIONS=""' "$KB_FILE"; then
    log "replacing empty XKBOPTIONS with $OPT"
    if [[ "${DRY_RUN:-0}" != "1" ]]; then
      sudo sed -i "s|^XKBOPTIONS=\"\"|XKBOPTIONS=\"${OPT}\"|" "$KB_FILE"
    fi
  else
    log "merging $OPT into existing XKBOPTIONS"
    if [[ "${DRY_RUN:-0}" != "1" ]]; then
      sudo sed -i -E "s|^XKBOPTIONS=\"([^\"]+)\"|XKBOPTIONS=\"\\1,${OPT}\"|" "$KB_FILE"
    fi
  fi
else
  log "appending XKBOPTIONS=\"$OPT\" to $KB_FILE"
  if [[ "${DRY_RUN:-0}" != "1" ]]; then
    printf 'XKBOPTIONS="%s"\n' "$OPT" | sudo tee -a "$KB_FILE" >/dev/null
  fi
fi

log "running dpkg-reconfigure xkb-data"
if [[ "${DRY_RUN:-0}" != "1" ]]; then
  sudo dpkg-reconfigure -f noninteractive xkb-data
fi

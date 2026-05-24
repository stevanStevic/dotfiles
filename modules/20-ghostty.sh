#!/usr/bin/env bash
# 20-ghostty.sh — install Ghostty (snap), register as terminal alternative,
# bind Ctrl+Alt+T -> ghostty under GNOME.

set -euo pipefail
IFS=$'\n\t'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$REPO_ROOT/lib/common.sh"

if [[ "${IN_CONTAINER:-0}" == "1" ]]; then
  log "container mode; skipping snap install"
else
  ensure_snap ghostty --classic
fi

ALT_PATH=/snap/bin/ghostty
if [[ -x "$ALT_PATH" ]]; then
  current="$(update-alternatives --query x-terminal-emulator 2>/dev/null \
             | awk '/^Alternative: /{print $2}' || true)"
  if echo "$current" | grep -q "^$ALT_PATH$"; then
    log "ghostty already registered as x-terminal-emulator alternative"
  else
    log "registering ghostty as x-terminal-emulator alternative"
    if [[ "${DRY_RUN:-0}" != "1" ]]; then
      sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$ALT_PATH" 50
    fi
  fi
else
  log "$ALT_PATH not present; skipping alternatives registration"
fi

# GNOME custom keybinding: Ctrl+Alt+T -> ghostty
if [[ "${IN_CONTAINER:-0}" == "1" || "${XDG_CURRENT_DESKTOP:-}" != *GNOME* ]]; then
  log "non-GNOME desktop or container (${XDG_CURRENT_DESKTOP:-unknown}); skipping shortcut"
  exit 0
fi

if ! have_cmd gsettings; then
  log "gsettings unavailable; skipping shortcut"
  exit 0
fi

CB_SCHEMA=org.gnome.settings-daemon.plugins.media-keys
CB_PATH=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/

current_list="$(gsettings get "$CB_SCHEMA" custom-keybindings 2>/dev/null || echo '@as []')"
if echo "$current_list" | grep -q "$CB_PATH"; then
  log "custom0 already in custom-keybindings list"
else
  log "adding $CB_PATH to custom-keybindings"
  if [[ "${DRY_RUN:-0}" != "1" ]]; then
    if [[ "$current_list" == "@as []" || "$current_list" == "[]" ]]; then
      gsettings set "$CB_SCHEMA" custom-keybindings "['$CB_PATH']"
    else
      new_list="${current_list%]}, '$CB_PATH']"
      gsettings set "$CB_SCHEMA" custom-keybindings "$new_list"
    fi
  fi
fi

KB_SCHEMA="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${CB_PATH}"
ensure_gsettings_kv "$KB_SCHEMA" name    'Ghostty'
ensure_gsettings_kv "$KB_SCHEMA" command "$ALT_PATH"
ensure_gsettings_kv "$KB_SCHEMA" binding '<Ctrl><Alt>t'

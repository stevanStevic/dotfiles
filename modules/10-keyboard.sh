#!/usr/bin/env bash
# 10-keyboard.sh — remap Caps Lock to Ctrl.
#
# Sets the option in two places:
#   1. /etc/default/keyboard  — system default (console + non-GNOME X sessions).
#   2. GNOME input-sources     — what a GNOME/Wayland session actually honors;
#      without this the file is ignored in the GUI and Caps Lock stays Caps Lock.

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

# ---- 1. /etc/default/keyboard (system default) ----
if grep -qE "^XKBOPTIONS=.*\\b${OPT}\\b" "$KB_FILE"; then
  log "$OPT already present in $KB_FILE"
else
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
  if [[ "${DRY_RUN:-0}" != "1" && "${IN_CONTAINER:-0}" != "1" ]]; then
    sudo dpkg-reconfigure -f noninteractive xkb-data
  fi
fi

# ---- 2. GNOME input-sources (Wayland/GNOME honors this, not the file) ----
# A GNOME session reads xkb options from this gsettings key and ignores
# /etc/default/keyboard for the GUI, so set it here too. mutter applies the
# change live on Wayland. Merge into any existing options rather than clobber.
if [[ "${IN_CONTAINER:-0}" == "1" || "${XDG_CURRENT_DESKTOP:-}" != *GNOME* ]]; then
  log "non-GNOME desktop or container (${XDG_CURRENT_DESKTOP:-unknown}); skipping GNOME xkb-options"
elif ! have_cmd gsettings; then
  log "gsettings unavailable; skipping GNOME xkb-options"
else
  IS_SCHEMA=org.gnome.desktop.input-sources
  current_opts="$(gsettings get "$IS_SCHEMA" xkb-options 2>/dev/null || echo '@as []')"
  if echo "$current_opts" | grep -q "'${OPT}'"; then
    log "$OPT already present in GNOME xkb-options"
  else
    log "adding $OPT to GNOME xkb-options"
    if [[ "${DRY_RUN:-0}" != "1" ]]; then
      if [[ "$current_opts" == "@as []" || "$current_opts" == "[]" ]]; then
        gsettings set "$IS_SCHEMA" xkb-options "['${OPT}']"
      else
        gsettings set "$IS_SCHEMA" xkb-options "${current_opts%]}, '${OPT}']"
      fi
    fi
  fi
fi

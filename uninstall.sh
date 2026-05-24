#!/usr/bin/env bash
# uninstall.sh — reverse what install.sh did. Apt packages are kept by default;
# pass --purge to also remove oh-my-zsh, snap-installed ghostty, and reset login shell.
#
# Usage:
#   ./uninstall.sh                 # reverse everything except packages
#   ./uninstall.sh ghostty zsh     # reverse only matching modules
#   ./uninstall.sh --purge         # also remove oh-my-zsh, ghostty snap, chsh back
#   ./uninstall.sh --dry-run       # log only

set -euo pipefail
IFS=$'\n\t'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$REPO_ROOT/lib/common.sh"

DRY_RUN=0
PURGE=0
selectors=()
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --purge) PURGE=1 ;;
    --*) log "unknown flag: $arg"; exit 2 ;;
    *) selectors+=("$arg") ;;
  esac
done
export DRY_RUN

want() {
  local name="$1"
  if [[ ${#selectors[@]} -eq 0 ]]; then return 0; fi
  for s in "${selectors[@]}"; do [[ "$name" == *"$s"* ]] && return 0; done
  return 1
}

# Restore most recent backup matching a glob pattern.
restore_latest_backup() {
  local original="$1" pattern="$2"
  local latest
  # shellcheck disable=SC2012,SC2086
  # backup filenames are timestamps, so `ls -t` is safe here.
  latest="$(ls -t $pattern 2>/dev/null | head -1 || true)"
  if [[ -z "$latest" ]]; then
    log "no backup to restore for $original"
    return 0
  fi
  log "restoring $original from $latest"
  if [[ "${DRY_RUN:-0}" != "1" ]]; then
    if [[ -w "$(dirname "$original")" ]]; then
      mv -f "$latest" "$original"
    else
      sudo mv -f "$latest" "$original"
    fi
  fi
}

# ---- symlinks ----
if want symlinks; then
  log "=== reversing symlinks ==="
  DOTFILES_DIR="$REPO_ROOT/dotfiles"
  while IFS= read -r link; do
    target="$(readlink "$link")"
    case "$target" in
      "$DOTFILES_DIR"/*)
        log "removing symlink $link"
        if [[ "${DRY_RUN:-0}" != "1" ]]; then rm "$link"; fi
        restore_latest_backup "$link" "${link}.bak-*"
        ;;
    esac
  done < <(find "$HOME" -maxdepth 3 -type l 2>/dev/null)
fi

# ---- keyboard ----
if want keyboard; then
  log "=== reversing keyboard ==="
  restore_latest_backup /etc/default/keyboard '/etc/default/keyboard.bak-*'
  log "running dpkg-reconfigure xkb-data"
  if [[ "${DRY_RUN:-0}" != "1" ]]; then
    sudo dpkg-reconfigure -f noninteractive xkb-data
  fi
fi

# ---- ghostty ----
if want ghostty; then
  log "=== reversing ghostty ==="
  if update-alternatives --query x-terminal-emulator 2>/dev/null \
     | grep -q '/snap/bin/ghostty'; then
    log "removing ghostty from x-terminal-emulator alternatives"
    if [[ "${DRY_RUN:-0}" != "1" ]]; then
      sudo update-alternatives --remove x-terminal-emulator /snap/bin/ghostty || true
    fi
  fi
  if have_cmd gsettings && [[ "${XDG_CURRENT_DESKTOP:-}" == *GNOME* ]]; then
    CB_SCHEMA=org.gnome.settings-daemon.plugins.media-keys
    CB_PATH=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/
    current_list="$(gsettings get "$CB_SCHEMA" custom-keybindings 2>/dev/null || echo '[]')"
    if echo "$current_list" | grep -q "$CB_PATH"; then
      log "removing $CB_PATH from custom-keybindings"
      if [[ "${DRY_RUN:-0}" != "1" ]]; then
        new_list="$(echo "$current_list" | sed "s|, *'$CB_PATH'||; s|'$CB_PATH', *||; s|'$CB_PATH'||")"
        gsettings set "$CB_SCHEMA" custom-keybindings "$new_list"
        gsettings reset-recursively "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${CB_PATH}" || true
      fi
    fi
  fi
  if [[ "$PURGE" == "1" ]] && snap list ghostty >/dev/null 2>&1; then
    log "snap remove ghostty (--purge)"
    if [[ "${DRY_RUN:-0}" != "1" ]]; then sudo snap remove ghostty; fi
  fi
fi

# ---- zsh ----
if want zsh && [[ "$PURGE" == "1" ]]; then
  log "=== reversing zsh (--purge) ==="
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log "removing $HOME/.oh-my-zsh"
    if [[ "${DRY_RUN:-0}" != "1" ]]; then rm -rf "$HOME/.oh-my-zsh"; fi
  fi
  if [[ -x /bin/bash ]]; then
    current_shell="$(getent passwd "$USER" | cut -d: -f7)"
    if [[ "$current_shell" != "/bin/bash" ]]; then
      log "chsh back to /bin/bash"
      if [[ "${DRY_RUN:-0}" != "1" ]]; then chsh -s /bin/bash "$USER"; fi
    fi
  fi
fi

# ---- fonts ----
if want fonts; then
  log "=== reversing fonts ==="
  for d in "$HOME/.local/share/fonts/JetBrainsMono-NerdFont" \
           "$HOME/.local/share/fonts/Meslo-NerdFont"; do
    if [[ -d "$d" ]]; then
      log "removing $d"
      if [[ "${DRY_RUN:-0}" != "1" ]]; then rm -rf "$d"; fi
    fi
  done
  log "running fc-cache -f"
  if [[ "${DRY_RUN:-0}" != "1" ]]; then fc-cache -f; fi
fi

log "uninstall done"

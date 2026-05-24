#!/usr/bin/env bash
# lib/common.sh — shared helpers for module scripts.
# Source this from each module: `source "$REPO_ROOT/lib/common.sh"`.
#
# Honors DRY_RUN=1 to log without acting.

set -euo pipefail
IFS=$'\n\t'

log() {
  printf '[setup] %s\n' "$*"
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

# _utc_ts: emit a UTC timestamp suitable for backup suffixes.
_utc_ts() {
  date -u +%Y%m%dT%H%M%SZ
}

# ensure_apt_pkg <pkg>...
# Installs only the missing packages in one apt-get call.
ensure_apt_pkg() {
  if [[ $# -eq 0 ]]; then return 0; fi
  local missing=() pkg
  for pkg in "$@"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
      missing+=("$pkg")
    fi
  done
  if [[ ${#missing[@]} -eq 0 ]]; then
    log "apt packages already installed: $*"
    return 0
  fi
  log "installing apt packages: ${missing[*]}"
  if [[ "${DRY_RUN:-0}" == "1" ]]; then return 0; fi
  sudo apt-get install -y "${missing[@]}"
}

# ensure_snap <pkg> [extra-args...]
ensure_snap() {
  local pkg="$1"; shift
  if snap list "$pkg" >/dev/null 2>&1; then
    log "snap already installed: $pkg"
    return 0
  fi
  log "installing snap: $pkg $*"
  if [[ "${DRY_RUN:-0}" == "1" ]]; then return 0; fi
  sudo snap install "$pkg" "$@"
}

# ensure_line_in_file <line> <file>
# Appends <line> to <file> if not already present (verbatim, full-line match).
# Takes a one-time backup before first modification.
ensure_line_in_file() {
  local line="$1" file="$2"
  if [[ -f "$file" ]] && grep -qxF -- "$line" "$file"; then
    return 0
  fi
  log "appending to $file: $line"
  if [[ "${DRY_RUN:-0}" == "1" ]]; then return 0; fi
  if [[ -f "$file" ]] && ! compgen -G "${file}.bak-*" >/dev/null; then
    local backup
    backup="${file}.bak-$(_utc_ts)"
    log "backing up $file -> $backup"
    if [[ -w "$(dirname "$file")" ]]; then
      cp -p "$file" "$backup"
    else
      sudo cp -p "$file" "$backup"
    fi
  fi
  if [[ -w "$file" || ( ! -e "$file" && -w "$(dirname "$file")" ) ]]; then
    printf '%s\n' "$line" >> "$file"
  else
    printf '%s\n' "$line" | sudo tee -a "$file" >/dev/null
  fi
}

# ensure_symlink <src> <target>
# Idempotent. Backs up pre-existing real files/dirs at <target>.
ensure_symlink() {
  local src="$1" target="$2"
  if [[ -L "$target" ]]; then
    local current
    current="$(readlink "$target")"
    if [[ "$current" == "$src" ]]; then
      return 0
    fi
  fi
  log "linking $target -> $src"
  if [[ "${DRY_RUN:-0}" == "1" ]]; then return 0; fi
  if [[ -e "$target" || -L "$target" ]]; then
    local backup
    backup="${target}.bak-$(_utc_ts)"
    log "backing up $target -> $backup"
    mv "$target" "$backup"
  fi
  mkdir -p "$(dirname "$target")"
  ln -s "$src" "$target"
}

# ensure_gsettings_kv <schema[:path]> <key> <value>
# Sets a gsettings key only if the current value differs.
ensure_gsettings_kv() {
  local schema="$1" key="$2" value="$3"
  if ! have_cmd gsettings; then
    log "gsettings unavailable; skipping ($schema $key)"
    return 0
  fi
  local current
  current="$(gsettings get "$schema" "$key" 2>/dev/null || true)"
  if [[ "$current" == "$value" || "$current" == "'$value'" ]]; then
    return 0
  fi
  log "gsettings set $schema $key = $value (was: $current)"
  if [[ "${DRY_RUN:-0}" == "1" ]]; then return 0; fi
  gsettings set "$schema" "$key" "$value"
}

# apt_refresh_if_stale: run apt-get update only if /var/lib/apt/lists is older than 24h.
apt_refresh_if_stale() {
  local lists=/var/lib/apt/lists
  local age_max=86400
  if [[ -d "$lists" ]]; then
    local mtime now age
    mtime=$(stat -c %Y "$lists" 2>/dev/null || echo 0)
    now=$(date +%s)
    age=$((now - mtime))
    if (( age < age_max )); then
      log "apt lists fresh (${age}s old); skipping update"
      return 0
    fi
  fi
  log "running apt-get update"
  if [[ "${DRY_RUN:-0}" == "1" ]]; then return 0; fi
  sudo apt-get update -y
}

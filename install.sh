#!/usr/bin/env bash
# install.sh — discover and run modules/*.sh in numeric order.
#
# Usage:
#   ./install.sh                  # run all modules
#   ./install.sh ghostty zsh      # run only matching modules (substring match)
#   ./install.sh --dry-run        # log only, no changes
#   ./install.sh --dry-run zsh    # combine

set -euo pipefail
IFS=$'\n\t'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$REPO_ROOT/lib/common.sh"

DRY_RUN=0
selectors=()
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help)
      sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    --*) log "unknown flag: $arg"; exit 2 ;;
    *) selectors+=("$arg") ;;
  esac
done
export DRY_RUN

mapfile -t all_modules < <(find "$REPO_ROOT/modules" -maxdepth 1 -type f -name '*.sh' | sort)

if [[ ${#all_modules[@]} -eq 0 ]]; then
  log "no modules found in $REPO_ROOT/modules"
  exit 1
fi

selected=()
if [[ ${#selectors[@]} -eq 0 ]]; then
  selected=("${all_modules[@]}")
else
  for m in "${all_modules[@]}"; do
    name="$(basename "$m" .sh)"
    short="${name#[0-9]*-}"
    for sel in "${selectors[@]}"; do
      if [[ "$short" == *"$sel"* ]]; then
        selected+=("$m")
        break
      fi
    done
  done
fi

if [[ ${#selected[@]} -eq 0 ]]; then
  log "no modules matched: ${selectors[*]}"
  exit 1
fi

if [[ "$DRY_RUN" == "1" ]]; then
  log "running ${#selected[@]} module(s) (dry-run)"
else
  log "running ${#selected[@]} module(s)"
fi
for m in "${selected[@]}"; do
  log "=== $(basename "$m") ==="
  if ! bash "$m"; then
    log "FAILED: $(basename "$m")"
    exit 1
  fi
done
log "done"

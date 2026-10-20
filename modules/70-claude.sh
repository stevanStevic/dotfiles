#!/usr/bin/env bash
# 70-claude.sh — Claude Code marketplaces, plugins and MCP servers from
# claude/manifest.tsv, for this machine's profile.
#
# Profiles: CLAUDE_PROFILE (comma list) if set, else "agent" in a *-agent
# account, "brain,server" in your account on loptech-ws and "brain,laptop"
# anywhere else. CLAUDE_CHECK=1 only reports drift (missing items, and
# installed items the manifest doesn't list), exit 1 on drift.

set -euo pipefail
IFS=$'\n\t'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$REPO_ROOT/lib/common.sh"

MANIFEST="$REPO_ROOT/claude/manifest.tsv"
if [[ "${USER:-}" == *-agent ]]; then
  PROFILE="${CLAUDE_PROFILE:-agent}"
elif [[ "$(hostname)" == loptech-ws ]]; then
  PROFILE="${CLAUDE_PROFILE:-brain,server}"
else
  PROFILE="${CLAUDE_PROFILE:-brain,laptop}"
fi
CHECK="${CLAUDE_CHECK:-0}"
drift=0

if ! have_cmd claude; then
  log "claude not installed; skipping"
  exit 0
fi
if ! have_cmd jq; then
  log "jq not installed; skipping"
  exit 0
fi

# rows <kind>: "name<TAB>source" for every manifest row of that kind in
# this profile.
rows() {
  awk -F'\t' -v kind="$1" -v profiles="$PROFILE" '
    BEGIN { n = split(profiles, want, ",") }
    /^#/ || NF < 4 || $1 != kind { next }
    { for (i = 1; i <= n; i++) if (("," $4 ",") ~ ("," want[i] ",")) { print $2 "\t" $3; next } }
  ' "$MANIFEST"
}

run() {
  local IFS=' '
  log "$*"
  if [[ "${DRY_RUN:-0}" == "1" ]]; then return 0; fi
  "$@"
}

# Your own plugins (claude/mods) are a local marketplace at ~/.claude/mods.
mods_link="$HOME/.claude/mods"
if [[ "$(readlink "$mods_link" 2>/dev/null)" != "$REPO_ROOT/claude/mods" ]]; then
  if [[ "$CHECK" == "1" ]]; then
    log "missing link: $mods_link -> $REPO_ROOT/claude/mods"
    drift=1
  elif [[ -e "$mods_link" && ! -L "$mods_link" ]]; then
    log "$mods_link is a real folder; move its plugins into claude/mods first"
  else
    run mkdir -p "$HOME/.claude"
    run ln -sfn "$REPO_ROOT/claude/mods" "$mods_link"
  fi
fi

have_markets="$(jq -r 'keys[]' "$HOME/.claude/plugins/known_marketplaces.json" 2>/dev/null || true)"
have_plugins="$(jq -r '.plugins | keys[]' "$HOME/.claude/plugins/installed_plugins.json" 2>/dev/null || true)"
have_mcp="$(jq -r '.mcpServers // {} | keys[]' "$HOME/.claude.json" 2>/dev/null || true)"

missing() {
  if [[ "$CHECK" == "1" ]]; then
    log "missing $1: $2"
    drift=1
    return 1
  fi
}

while IFS=$'\t' read -r name src; do
  grep -qxF "$name" <<<"$have_markets" && continue
  missing marketplace "$name" || continue
  run claude plugin marketplace add "${src/#\~/$HOME}"
done < <(rows marketplace)

while IFS=$'\t' read -r name _; do
  grep -qxF "$name" <<<"$have_plugins" && continue
  missing plugin "$name" || continue
  run claude plugin install "$name" --scope user
done < <(rows plugin)

while IFS=$'\t' read -r name src; do
  grep -qxF "$name" <<<"$have_mcp" && continue
  missing mcp "$name" || continue
  # URL first, then any extra flags (e.g. Slack's fixed OAuth client).
  IFS=' ' read -r url flags <<<"$src"
  IFS=' ' read -r -a extra <<<"${flags:-}"
  run claude mcp add --scope user --transport http "${extra[@]}" "$name" "$url"
done < <(rows mcp-http)

while IFS=$'\t' read -r name cmd; do
  grep -qxF "$name" <<<"$have_mcp" && continue
  missing mcp "$name" || continue
  IFS=' ' read -r -a argv <<<"$cmd"
  run claude mcp add --scope user "$name" -- "${argv[@]}"
done < <(rows mcp-stdio)

# Installed but not in the manifest: add it there, or remove it here.
if [[ "$CHECK" == "1" ]]; then
  want_plugins="$(rows plugin | cut -f1)"
  want_mcp="$( (rows mcp-http; rows mcp-stdio) | cut -f1)"
  while IFS= read -r p; do
    [[ -z "$p" ]] && continue
    grep -qxF "$p" <<<"$want_plugins" || { log "not in manifest: plugin $p"; drift=1; }
  done <<<"$have_plugins"
  while IFS= read -r m; do
    [[ -z "$m" ]] && continue
    grep -qxF "$m" <<<"$want_mcp" || { log "not in manifest: mcp $m"; drift=1; }
  done <<<"$have_mcp"
  [[ "$drift" == "0" ]] && log "claude ($PROFILE): matches the manifest"
  exit "$drift"
fi

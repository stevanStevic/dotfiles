#!/usr/bin/env bash
# Unit tests for pure-logic helpers in lib/common.sh.
# Runs in a tempdir; does not touch the system.

set -euo pipefail
IFS=$'\n\t'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$REPO_ROOT/lib/common.sh"

PASS=0
FAIL=0

assert_eq() {
  local expected="$1" actual="$2" msg="$3"
  if [[ "$expected" == "$actual" ]]; then
    printf '  PASS: %s\n' "$msg"
    PASS=$((PASS + 1))
  else
    printf '  FAIL: %s\n    expected: %s\n    actual:   %s\n' "$msg" "$expected" "$actual"
    FAIL=$((FAIL + 1))
  fi
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "test: have_cmd"
if have_cmd ls; then PASS=$((PASS+1)); echo "  PASS: have_cmd ls"; else FAIL=$((FAIL+1)); echo "  FAIL: have_cmd ls"; fi
if ! have_cmd this-command-does-not-exist-xyz; then PASS=$((PASS+1)); echo "  PASS: have_cmd negative"; else FAIL=$((FAIL+1)); echo "  FAIL: have_cmd negative"; fi

echo "test: ensure_line_in_file appends new line"
printf 'existing\n' > "$TMP/f1"
ensure_line_in_file 'newline' "$TMP/f1"
assert_eq "$(printf 'existing\nnewline')" "$(cat "$TMP/f1")" "line appended"

echo "test: ensure_line_in_file is idempotent"
ensure_line_in_file 'newline' "$TMP/f1"
assert_eq "$(printf 'existing\nnewline')" "$(cat "$TMP/f1")" "second call no-op"

echo "test: ensure_symlink creates symlink"
mkdir -p "$TMP/sym"
echo "src content" > "$TMP/sym/src"
ensure_symlink "$TMP/sym/src" "$TMP/sym/target"
assert_eq "$TMP/sym/src" "$(readlink "$TMP/sym/target")" "symlink points to src"

echo "test: ensure_symlink is idempotent"
ensure_symlink "$TMP/sym/src" "$TMP/sym/target"
assert_eq "$TMP/sym/src" "$(readlink "$TMP/sym/target")" "second call no-op"

echo "test: ensure_symlink backs up pre-existing file"
echo "real file" > "$TMP/sym/target2"
ensure_symlink "$TMP/sym/src" "$TMP/sym/target2"
assert_eq "$TMP/sym/src" "$(readlink "$TMP/sym/target2")" "target2 is now symlink"
backup_count=$(find "$TMP/sym" -maxdepth 1 -name 'target2.bak-*' | wc -l)
assert_eq "1" "$backup_count" "one backup file created for target2"

echo "test: ensure_symlink backs up pre-existing directory"
mkdir "$TMP/sym/srcdir"
echo "child" > "$TMP/sym/srcdir/child"
mkdir "$TMP/sym/targetdir"
echo "old child" > "$TMP/sym/targetdir/oldchild"
ensure_symlink "$TMP/sym/srcdir" "$TMP/sym/targetdir"
assert_eq "$TMP/sym/srcdir" "$(readlink "$TMP/sym/targetdir")" "targetdir is now symlink"
dir_backup_count=$(find "$TMP/sym" -maxdepth 1 -type d -name 'targetdir.bak-*' | wc -l)
assert_eq "1" "$dir_backup_count" "one backup dir created for targetdir"

echo
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]

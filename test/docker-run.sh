#!/usr/bin/env bash
# test/docker-run.sh — run install.sh twice inside ubuntu:24.04; verify idempotency.

set -euo pipefail
IFS=$'\n\t'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="ubuntu:24.04"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not installed; aborting"
  exit 1
fi

container_script='
set -euo pipefail
cd /work
apt-get update -y >/dev/null
apt-get install -y sudo curl ca-certificates unzip software-properties-common >/dev/null
echo "----- first install run -----"
IN_CONTAINER=1 ./install.sh
echo "----- second install run (idempotency check) -----"
IN_CONTAINER=1 ./install.sh 2>&1 | tee /tmp/second.log
echo "----- assertions -----"
if grep -E "installing |backing up " /tmp/second.log; then
  echo "FAIL: second run performed install/backup actions"
  exit 1
fi
echo "OK: second run produced no install/backup actions"
'

docker run --rm -v "$REPO_ROOT":/work:ro -w /work "$IMAGE" bash -c "$container_script"

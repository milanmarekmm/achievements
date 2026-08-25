#!/usr/bin/env bash
# Shared helpers for the achievement scripts.
set -euo pipefail

REPO="${REPO:-milanmarekmm/achievements}"
OWNER="${REPO%%/*}"
NAME="${REPO##*/}"
# GitHub secondary rate limits: keep >=1s between mutating requests.
THROTTLE="${THROTTLE:-1.2}"

log()   { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }
pause() { sleep "$THROTTLE"; }

# retry <attempts> <command...> — backs off on secondary rate limiting.
retry() {
  local attempts=$1; shift
  local i=1
  while true; do
    if "$@"; then return 0; fi
    if (( i >= attempts )); then
      log "FAILED after ${attempts} attempts: $*"
      return 1
    fi
    local wait=$(( i * 20 ))
    log "  retry ${i}/${attempts} in ${wait}s"
    sleep "$wait"
    i=$(( i + 1 ))
  done
}

require_clean_main() {
  git -C "$(git rev-parse --show-toplevel)" fetch -q origin main
  git checkout -q main
  git reset -q --hard origin/main
}

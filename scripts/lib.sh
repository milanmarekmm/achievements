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

# Refuse to run if the checkout points somewhere other than $REPO — otherwise the
# scripts happily push branches into whatever repo origin happens to be.
require_matching_origin() {
  local origin
  origin=$(git remote get-url origin 2>/dev/null) || return 0
  case "$origin" in
    *"${REPO}"*) return 0 ;;
    *)
      echo "ABORT: git origin is '${origin}' but REPO=${REPO}." >&2
      echo "       Run this inside a clone of ${REPO}, or set REPO to match origin." >&2
      exit 1 ;;
  esac
}

require_clean_main() {
  require_matching_origin
  git -C "$(git rev-parse --show-toplevel)" fetch -q origin main
  git checkout -q main
  git reset -q --hard origin/main
}

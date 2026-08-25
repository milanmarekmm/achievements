#!/usr/bin/env bash
# Delete remote branches left behind by merged automation PRs.
source "$(dirname "$0")/lib.sh"
gh api --paginate "repos/${REPO}/branches?per_page=100" --jq '.[].name' \
  | grep -E '^ps/' \
  | while read -r b; do
      gh api -X DELETE "repos/${REPO}/git/refs/heads/${b}" >/dev/null 2>&1 && log "deleted ${b}"
      sleep 0.4
    done

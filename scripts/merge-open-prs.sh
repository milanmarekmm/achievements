#!/usr/bin/env bash
# Merge every open pull request in YOUR repo that somebody ELSE opened.
# This is the half the PR author cannot do — self-merged PRs do not seem to count.
#
#   scripts/merge-open-prs.sh <owner/repo>
source "$(dirname "$0")/lib.sh"

target="${1:?usage: $0 <owner/repo>}"
me=$(gh api user --jq .login)

gh api --paginate "repos/${target}/pulls?state=open&per_page=100" \
  --jq ".[] | select(.user.login != \"${me}\") | \"\(.number)\t\(.user.login)\"" \
| while IFS=$'\t' read -r num who; do
    [ -z "$num" ] && continue
    i=1; merged=0
    while [ "$i" -le 5 ]; do
      if gh api -X PUT "repos/${target}/pulls/${num}/merge" -f merge_method=squash >/dev/null 2>&1; then
        merged=1; break
      fi
      sleep $(( i * 5 )); i=$(( i + 1 ))
    done
    if [ "$merged" = 1 ]; then log "merged #${num} (by ${who})"; else log "FAILED #${num}"; fi
    pause
  done

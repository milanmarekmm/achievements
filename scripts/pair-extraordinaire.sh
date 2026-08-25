#!/usr/bin/env bash
# Pair Extraordinaire: merged PRs carrying a Co-authored-by trailer.
# Tiers at 1 / 10 / 24 / 48 co-authored merged PRs.
#
#   scripts/pair-extraordinaire.sh <count> "Name <ID+login@users.noreply.github.com>"
#
# The co-author must be a REAL, DIFFERENT GitHub account — GitHub does not count
# a commit you co-authored with yourself, and attributing commits to somebody who
# did not agree to it is forging authorship. Use your own second account, or ask
# a friend first. Find any user's noreply address with:
#   gh api users/<login> --jq '"\(.id)+\(.login)@users.noreply.github.com"'
source "$(dirname "$0")/lib.sh"

count="${1:-10}"
coauthor="${2:-}"

if [ -z "$coauthor" ]; then
  echo "usage: $0 <count> \"Name <ID+login@users.noreply.github.com>\"" >&2
  exit 2
fi

gh api -X POST "repos/${REPO}/labels" -f name=pair-extraordinaire -f color=5319e7 \
  -f description="PR with a co-authored commit" >/dev/null 2>&1 || true

log "co-author: ${coauthor}"
COAUTHOR="$coauthor" PR_LABEL=pair-extraordinaire "$(dirname "$0")/pull-shark.sh" "$count"

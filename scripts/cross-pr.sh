#!/usr/bin/env bash
# Open pull requests from YOUR FORK into someone else's repo, so THAT person
# merges them. Pull Shark appears to ignore PRs you merge yourself, so the merge
# has to be done by the other account.
#
#   scripts/cross-pr.sh <upstream-owner/repo> [count]
#
# Run this inside a clone of YOUR FORK of that repo. Create the fork first with:
#   gh api -X POST repos/<upstream>/forks
#
# Env:
#   COAUTHOR="Name <email>"   also add a Co-authored-by trailer
source "$(dirname "$0")/lib.sh"

upstream="${1:?usage: $0 <upstream-owner/repo> [count]}"
count="${2:-16}"
coauthor="${COAUTHOR:-}"

cd "$(git rev-parse --show-toplevel)"
origin_url=$(git remote get-url origin)
fork=$(printf '%s' "$origin_url" | sed -E 's#.*github\.com[:/]##; s#\.git$##')

if [ "$fork" = "$upstream" ]; then
  echo "ABORT: origin is the upstream repo itself (${fork})." >&2
  echo "       Run this inside a clone of your own fork." >&2
  exit 1
fi

fork_owner="${fork%%/*}"
base=$(gh api "repos/${upstream}" --jq .default_branch)
log "fork=${fork}  upstream=${upstream}  base=${base}"

git fetch -q origin "$base"
git checkout -q "$base"
git reset -q --hard "origin/${base}"

stamp="$(date +%Y%m%d%H%M%S)"
branches=""
for i in $(seq 1 "$count"); do
  b="xr/${stamp}-${i}"
  git checkout -q -b "$b" "$base"
  mkdir -p cross
  printf '# cross PR %s\n\n%s\n' "$i" "$(date -u +%FT%TZ)" > "cross/${stamp}-${i}.md"
  git add "cross/${stamp}-${i}.md"
  if [ -n "$coauthor" ]; then
    git commit -q -m "Cross-repo PR ${i}" -m "Co-authored-by: ${coauthor}"
  else
    git commit -q -m "Cross-repo PR ${i}"
  fi
  git checkout -q "$base"
  branches="${branches} ${b}"
done

log "pushing ${count} branches to ${fork}"
git push -q origin $branches

ok=0
for b in $branches; do
  if url=$(gh api -X POST "repos/${upstream}/pulls" \
             -f title="Cross-repo PR ${b#xr/}" -f head="${fork_owner}:${b}" -f base="$base" \
             -f body="Please merge — testing whether Pull Shark counts PRs merged by another account." \
             --jq .html_url 2>/dev/null); then
    ok=$(( ok + 1 )); log "opened ${url}"
  else
    log "FAILED to open PR for ${b}"
  fi
  git branch -qD "$b" 2>/dev/null || true
  pause
done

log "done: ${ok} pull requests opened against ${upstream}"

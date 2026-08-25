#!/usr/bin/env bash
# Pull Shark: merge pull requests. Tiers at 2 / 16 / 128 / 1024 merged PRs.
#
#   scripts/pull-shark.sh [count]
#
# Env:
#   COAUTHOR="Name <email>"   add a Co-authored-by trailer (Pair Extraordinaire)
#   PR_LABEL=pair-extraordinaire
source "$(dirname "$0")/lib.sh"

count="${1:-16}"
coauthor="${COAUTHOR:-}"
label="${PR_LABEL:-}"
stamp="$(date +%Y%m%d%H%M%S)"

cd "$(git rev-parse --show-toplevel)"
require_clean_main

create_pr() { # <branch> <title> -> prints PR number
  local b=$1 t=$2 i=1 n
  while (( i <= 4 )); do
    if n=$(gh api -X POST "repos/${REPO}/pulls" -f title="$t" -f head="$b" -f base=main \
             -f body="Automated pull request." --jq .number 2>/dev/null); then
      printf '%s' "$n"; return 0
    fi
    sleep $(( i * 20 )); i=$(( i + 1 ))
  done
  return 1
}

merge_pr() { # <number> — GitHub computes mergeability async, so retry
  local n=$1 i=1
  while (( i <= 6 )); do
    if gh api -X PUT "repos/${REPO}/pulls/${n}/merge" -f merge_method=squash >/dev/null 2>&1; then
      return 0
    fi
    sleep $(( i * 5 )); i=$(( i + 1 ))
  done
  return 1
}

log "building ${count} branches"
branches=()
for i in $(seq 1 "$count"); do
  b="ps/${stamp}-${i}"
  f="prs/${stamp}-${i}.md"
  git checkout -q -b "$b" main
  printf '# PR %s\n\nGenerated %s\n' "$i" "$(date -u +%FT%TZ)" > "$f"
  git add "$f"
  if [ -n "$coauthor" ]; then
    git commit -q -m "Add ${f}" -m "Co-authored-by: ${coauthor}"
  else
    git commit -q -m "Add ${f}"
  fi
  git checkout -q main
  branches+=("$b")
done

log "pushing ${#branches[@]} branches"
chunk=40
for (( i=0; i<${#branches[@]}; i+=chunk )); do
  git push -q origin "${branches[@]:i:chunk}"
  log "  pushed $(( i + 1 ))-$(( i + chunk < ${#branches[@]} ? i + chunk : ${#branches[@]} ))"
done

ok=0; fail=0
for b in "${branches[@]}"; do
  if n=$(create_pr "$b" "${b#ps/}: automated pull request"); then
    pause
    if [ -n "$label" ]; then
      gh api -X POST "repos/${REPO}/issues/${n}/labels" -f "labels[]=${label}" >/dev/null 2>&1 || true
    fi
    if merge_pr "$n"; then
      ok=$(( ok + 1 )); log "merged #${n}  (${ok}/${count})"
    else
      fail=$(( fail + 1 )); log "MERGE FAILED #${n}"
    fi
  else
    fail=$(( fail + 1 )); log "CREATE FAILED ${b}"
  fi
  git branch -qD "$b" 2>/dev/null || true
  pause
done

require_clean_main
log "done: ${ok} merged, ${fail} failed"

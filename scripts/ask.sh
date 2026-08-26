#!/usr/bin/env bash
# Ask questions in SOMEONE ELSE'S repo so they can earn Galaxy Brain by answering.
# Galaxy Brain only counts answers where the question was asked by a different
# person, so this is the half your partner cannot do for themselves.
#
#   scripts/ask.sh <owner/repo> [count]
source "$(dirname "$0")/lib.sh"

target="${1:?usage: $0 <owner/repo> [count]}"
count="${2:-32}"
o="${target%%/*}"; n="${target##*/}"

read -r repo_id cat_id <<<"$(gh api graphql -f query='
  query($o:String!,$n:String!){repository(owner:$o,name:$n){
    id discussionCategories(first:25){nodes{id isAnswerable}}}}' \
  -f o="$o" -f n="$n" \
  --jq '[.data.repository.id,(.data.repository.discussionCategories.nodes[]|select(.isAnswerable)|.id)][0:2]|@tsv')"

[ -z "${cat_id:-}" ] && { echo "no answerable Q&A category in ${target}" >&2; exit 1; }

TOPICS=("branch protection" "squash vs merge commits" "discussion categories" "repo labels"
        "GitHub Actions caching" "fork workflows" "release tagging" "codeowners"
        "draft pull requests" "issue templates")

for i in $(seq 1 "$count"); do
  topic="${TOPICS[$(( (i - 1) % ${#TOPICS[@]} ))]}"
  gh api graphql -f query='
    mutation($r:ID!,$c:ID!,$t:String!,$b:String!){
      createDiscussion(input:{repositoryId:$r,categoryId:$c,title:$t,body:$b}){discussion{number}}}' \
    -f r="$repo_id" -f c="$cat_id" \
    -f t="Q${i}: how does ${topic} work in this setup?" \
    -f b="Question ${i}. Looking for a short explanation of ${topic} and when to reach for it." \
    --jq '.data.createDiscussion.discussion.number' >/dev/null 2>&1 \
    && log "asked ${i}/${count}" || log "ask ${i} failed"
  pause
done

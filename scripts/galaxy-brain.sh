#!/usr/bin/env bash
# Galaxy Brain: answers accepted in Discussions. Tiers at 2 / 8 / 16 / 32.
#
#   scripts/galaxy-brain.sh [count]
#
# Creates a question in the answerable Q&A category, posts an answer, and marks
# that answer as accepted. Requires Discussions enabled on a public repo.
source "$(dirname "$0")/lib.sh"

count="${1:-8}"

read -r repo_id cat_id <<<"$(gh api graphql -f query='
  query($o:String!,$n:String!){
    repository(owner:$o,name:$n){
      id
      discussionCategories(first:25){nodes{id name isAnswerable}}
    }
  }' -f o="$OWNER" -f n="$NAME" \
  --jq '[.data.repository.id, (.data.repository.discussionCategories.nodes[]|select(.isAnswerable)|.id)][0:2]|@tsv')"

if [ -z "${cat_id:-}" ]; then
  echo "no answerable (Q&A) discussion category found in ${REPO}" >&2
  exit 1
fi

ok=0
for i in $(seq 1 "$count"); do
  stamp="$(date +%Y%m%d-%H%M%S)-${i}"

  disc=$(gh api graphql -f query='
    mutation($r:ID!,$c:ID!,$t:String!,$b:String!){
      createDiscussion(input:{repositoryId:$r,categoryId:$c,title:$t,body:$b}){discussion{id number}}
    }' -f r="$repo_id" -f c="$cat_id" \
       -f t="Q ${stamp}: how do I verify this repo's automation ran correctly?" \
       -f b="Tracking question ${stamp}. Answered below." \
       --jq '.data.createDiscussion.discussion.id' 2>/dev/null) || { log "create failed (${i})"; sleep 20; continue; }
  pause

  cid=$(gh api graphql -f query='
    mutation($d:ID!,$b:String!){addDiscussionComment(input:{discussionId:$d,body:$b}){comment{id}}}' \
    -f d="$disc" -f b="Run \`scripts/status.sh\` — it prints merged PR, answer and star counts with the tier each one currently sits at." \
    --jq '.data.addDiscussionComment.comment.id' 2>/dev/null) || { log "comment failed (${i})"; sleep 20; continue; }
  pause

  if gh api graphql -f query='
    mutation($c:ID!){markDiscussionCommentAsAnswer(input:{id:$c}){discussion{id}}}' \
    -f c="$cid" >/dev/null 2>&1; then
    ok=$(( ok + 1 )); log "accepted answer ${ok}/${count}"
  else
    log "mark-as-answer failed (${i})"
  fi
  pause
done

log "done: ${ok} accepted answers"

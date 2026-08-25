#!/usr/bin/env bash
# Find FRESH unanswered Q&A discussions worth answering.
#
#   scripts/find-questions.sh [max_age_days]   (default 7)
#
# Old questions are near-worthless for Galaxy Brain: the asker has to come back
# and click "Mark as answer", and after a few weeks they never do. Answer while
# they are still watching the thread.
source "$(dirname "$0")/lib.sh"

MAX_AGE_DAYS="${1:-7}"
REPOS="${REPOS:-drizzle-team/drizzle-orm shadcn-ui/ui vercel/next.js supabase/supabase tailwindlabs/tailwindcss}"

cutoff=$(date -u -v-"${MAX_AGE_DAYS}"d +%Y-%m-%d 2>/dev/null || date -u -d "${MAX_AGE_DAYS} days ago" +%Y-%m-%d)
echo "unanswered Q&A created since ${cutoff}"
echo

for r in $REPOS; do
  o="${r%%/*}"; n="${r##*/}"
  cid=$(gh api graphql -f query='query($o:String!,$n:String!){repository(owner:$o,name:$n){discussionCategories(first:25){nodes{id isAnswerable}}}}' \
        -f o="$o" -f n="$n" --jq '.data.repository.discussionCategories.nodes[]|select(.isAnswerable)|.id' 2>/dev/null | head -1)
  [ -z "$cid" ] && continue

  gh api graphql -f query='query($o:String!,$n:String!,$c:ID!){
      repository(owner:$o,name:$n){
        discussions(first:25,answered:false,categoryId:$c,orderBy:{field:CREATED_AT,direction:DESC}){
          nodes{number title url createdAt comments{totalCount} author{login}}}}}' \
    -f o="$o" -f n="$n" -f c="$cid" 2>/dev/null \
  | jq -r --arg cut "$cutoff" --arg repo "$r" '
      .data.repository.discussions.nodes[]
      | select(.createdAt[0:10] >= $cut)
      | "\($repo)  #\(.number)  \(.createdAt[0:10])  replies=\(.comments.totalCount)\n  \(.title)\n  \(.url)\n"'
  sleep 0.5
done

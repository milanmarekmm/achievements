#!/usr/bin/env bash
# Mark the first answer written by SOMEONE ELSE as accepted, on every unanswered
# question YOU asked. This is the click that grants them Galaxy Brain — it cannot
# be done by the person who wrote the answer.
#
#   scripts/accept.sh <owner/repo>
source "$(dirname "$0")/lib.sh"

target="${1:?usage: $0 <owner/repo>}"
o="${target%%/*}"; n="${target##*/}"
me=$(gh api user --jq .login)

gh api graphql -f query='
  query($o:String!,$n:String!){repository(owner:$o,name:$n){
    discussions(first:100,answered:false,orderBy:{field:CREATED_AT,direction:DESC}){
      nodes{number author{login} category{isAnswerable}
            comments(first:10){nodes{id author{login}}}}}}}' \
  -f o="$o" -f n="$n" \
| jq -r --arg me "$me" '.data.repository.discussions.nodes[]
      | select(.category.isAnswerable and .author.login == $me)
      | . as $d
      | [$d.comments.nodes[] | select(.author.login != $me) | .id][0] // empty
      | "\($d.number)\t\(.)"' \
| while IFS=$'\t' read -r num cid; do
    [ -z "$cid" ] && continue
    if gh api graphql -f query='mutation($c:ID!){markDiscussionCommentAsAnswer(input:{id:$c}){discussion{number}}}' \
         -f c="$cid" >/dev/null 2>&1; then
      log "accepted answer on #${num}"
    else
      log "accept #${num} FAILED"
    fi
    pause
  done

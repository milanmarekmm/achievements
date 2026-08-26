#!/usr/bin/env bash
# Answer every unanswered Q&A question in a repo that was asked by SOMEONE ELSE.
# Those are the only ones that can ever count toward Galaxy Brain.
#
#   scripts/answer-open-questions.sh [owner/repo]
source "$(dirname "$0")/lib.sh"

target="${1:-$REPO}"
o="${target%%/*}"; n="${target##*/}"
me=$(gh api user --jq .login)

gh api graphql -f query='
  query($o:String!,$n:String!){repository(owner:$o,name:$n){
    discussions(first:100,answered:false,orderBy:{field:CREATED_AT,direction:DESC}){
      nodes{id number title author{login} category{isAnswerable}}}}}' \
  -f o="$o" -f n="$n" \
| jq -r --arg me "$me" '.data.repository.discussions.nodes[]
      | select(.category.isAnswerable and .author.login != $me)
      | "\(.id)\t\(.number)\t\(.title)"' \
| while IFS=$'\t' read -r id num title; do
    [ -z "$id" ] && continue
    body="Short version: it depends on what you are optimising for.

For **${title#*: }** the practical rule is to start with GitHub's default behaviour and
only add configuration once you hit a real problem — these settings exist to solve
specific pain, and adopting them pre-emptively just adds moving parts.

The concrete setup used here lives in \`scripts/\`, and the README documents which
achievement each piece targets and which ones cannot be earned alone."
    if gh api graphql -f query='mutation($d:ID!,$b:String!){addDiscussionComment(input:{discussionId:$d,body:$b}){comment{id}}}' \
         -f d="$id" -f b="$body" >/dev/null 2>&1; then
      log "answered #${num}"
    else
      log "answer #${num} FAILED"
    fi
    pause
  done

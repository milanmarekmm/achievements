#!/usr/bin/env bash
# Current achievement progress for the authenticated user.
source "$(dirname "$0")/lib.sh"
me=$(gh api user --jq .login)

tier() { # tier <count> <b> <s> <g> <p>
  local n=$1
  if   (( n >= $5 )); then echo "PLATINUM"
  elif (( n >= $4 )); then echo "GOLD"
  elif (( n >= $3 )); then echo "SILVER"
  elif (( n >= $2 )); then echo "BRONZE"
  else echo "-"; fi
}

merged=$(gh api -X GET search/issues -f q="is:pr author:${me} is:merged is:public" --jq .total_count)
printf 'Pull Shark          %5s merged public PRs   -> %s (2/16/128/1024)\n' "$merged" "$(tier "$merged" 2 16 128 1024)"

answers=$(gh api graphql -f query="query(\$o:String!,\$n:String!){repository(owner:\$o,name:\$n){discussions(first:100,answered:true){totalCount}}}" \
  -f o="$OWNER" -f n="$NAME" --jq '.data.repository.discussions.totalCount' 2>/dev/null || echo 0)
printf 'Galaxy Brain        %5s accepted answers    -> %s (2/8/16/32)\n' "$answers" "$(tier "$answers" 2 8 16 32)"

pairs=$(gh api -X GET search/issues -f q="is:pr author:${me} is:merged is:public label:pair-extraordinaire" --jq .total_count 2>/dev/null || echo 0)
printf 'Pair Extraordinaire %5s labelled co-authored PRs in this repo\n' "$pairs"

stars=$(gh api "repos/${REPO}" --jq .stargazers_count)
printf 'Starstruck          %5s stars on %s -> %s (16/128/512/4096)\n' "$stars" "$REPO" "$(tier "$stars" 16 128 512 4096)"

echo
echo "Profile: https://github.com/${me}?tab=achievements"

# achievements

Sandbox repo for unlocking GitHub profile achievements. Isolated on purpose — nothing here touches any other project.

## Achievement status

| Achievement | Requirement | Tiers | Automatable here |
|---|---|---|---|
| YOLO | Merge a PR without review | — | already unlocked |
| Quickdraw | Close an issue/PR within 5 minutes of opening | — | yes |
| Pull Shark | Merged pull requests | 2 / 16 / 128 / 1024 | yes |
| Galaxy Brain | Accepted answers in Discussions | 2 / 8 / 16 / 32 | yes |
| Pair Extraordinaire | Merged PRs with a co-authored commit | 1 / 10 / 24 / 48 | needs a second GitHub identity |
| Starstruck | Stars on one repo | 16 / 128 / 512 / 4096 | no — needs real people |
| Public Sponsor | Sponsor someone via GitHub Sponsors | — | no — needs a payment you make |
| Heart On Your Sleeve | retired by GitHub (2022) | — | no longer awarded |
| Open Sourcerer | retired by GitHub (2022) | — | no longer awarded |
| Arctic Code Vault | retired (2020 snapshot only) | — | no longer awarded |

Achievements only count in **public** repos, and the profile must have *Settings → Profile → Show Achievements* enabled.

## Scripts

```bash
scripts/quickdraw.sh                  # open + instantly close an issue
scripts/pull-shark.sh 16              # create, push and merge 16 PRs
scripts/galaxy-brain.sh 8             # create 8 Q&A discussions, answer + accept each
scripts/pair-extraordinaire.sh 10 "Name <id+user@users.noreply.github.com>"
scripts/status.sh                     # current counts + tier progress
```

All scripts throttle themselves to stay under GitHub's secondary rate limits.

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

## Findings (2026-08-25 / 26)

What actually happened when the scripts ran against a single-contributor repo:

- 178 merged public PRs, 32 accepted discussion answers, 48 co-authored merged PRs.
- Only **Quickdraw** and **YOLO** ever appeared on the profile — the two achievements
  that need nobody but you.
- A second account (`Skeetek`) ran the same scripts independently and landed in exactly
  the same state: Quickdraw + YOLO only.
- Cross-repo test: PRs authored here, merged by a *different* account in *their* repo.
  Still nothing after ~20 hours.

Two constraints reported by the GitHub community that the bulk runs violated:

1. **Refresh takes 24–48 hours**, sometimes longer — instant feedback is not expected.
2. **PRs must be merged on separate calendar days.** Every one of the 178 merges landed
   inside the same 20-minute window on 2026-08-25, which under this rule counts as a
   single day no matter the volume.

Community reports also state GitHub patched self-merge farming in throwaway repos.

Conclusion so far: volume does nothing. The collaboration achievements are gated on
things you do not control — another person merging, another person accepting an answer,
and elapsed calendar days.

#!/usr/bin/env bash
# Quickdraw: close an issue (or PR) within 5 minutes of opening it.
source "$(dirname "$0")/lib.sh"

title="Quickdraw $(date +%Y%m%d-%H%M%S)"
num=$(gh issue create --repo "$REPO" --title "$title" \
        --body "Opened and closed immediately — Quickdraw achievement." \
        | grep -oE '[0-9]+$')
log "opened issue #${num}"
sleep 2
gh issue close "$num" --repo "$REPO" --reason "not planned" >/dev/null
log "closed issue #${num} — Quickdraw done"

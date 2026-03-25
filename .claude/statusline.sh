#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

# Build progress bar
BAR_WIDTH=10
FILLED=$((PCT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && printf -v FILL "%${FILLED}s" && BAR="${FILL// /▓}"
[ "$EMPTY" -gt 0 ] && printf -v PAD "%${EMPTY}s" && BAR="${BAR}${PAD// /░}"

# PR link if available, otherwise repo link
PR_URL=$(gh pr view --json url -q '.url' 2>/dev/null)

if [ -n "$PR_URL" ]; then
    echo "[$MODEL] $BAR ${PCT}% | $PR_URL"
else
    REMOTE=$(git remote get-url origin 2>/dev/null | sed 's|ssh://git@github.com/|https://github.com/|' | sed 's|git@github.com:|https://github.com/|' | sed 's/\.git$//')
    if [ -n "$REMOTE" ]; then
        echo "[$MODEL] $BAR ${PCT}% | $REMOTE"
    else
        echo "[$MODEL] $BAR ${PCT}%"
    fi
fi

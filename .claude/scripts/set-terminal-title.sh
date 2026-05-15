#!/usr/bin/env bash
# Set terminal tab title from the latest user prompt in this Claude Code session.
# Used by UserPromptSubmit / Stop hooks. Writes directly to /dev/tty so Claude
# does not see escape sequences in stdout.

set -u

INPUT=$(cat)

# Both UserPromptSubmit and Stop hooks provide transcript_path
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty' 2>/dev/null)

# For UserPromptSubmit, the prompt is directly in the payload — use it first
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)

# Otherwise pull last user-text message from the transcript
if [ -z "$PROMPT" ] && [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  PROMPT=$(jq -r 'select(.type=="user" and (.message.content | type)=="string") | .message.content' "$TRANSCRIPT" 2>/dev/null | tail -1)
fi

[ -z "$PROMPT" ] && exit 0

# Truncate to first line, max 25 Japanese chars. Drop leading slash-commands.
TITLE=$(printf '%s' "$PROMPT" | python3 -c '
import sys
text = sys.stdin.read()
line = next((l.strip() for l in text.splitlines() if l.strip()), "")
# Skip leading slash command (e.g. "/herp-scheduling ..."), keep argument
if line.startswith("/"):
    parts = line.split(None, 1)
    line = parts[1] if len(parts) > 1 else parts[0]
limit = 25
if len(line) > limit:
    line = line[:limit] + "…"
print(line)
' 2>/dev/null)

[ -z "$TITLE" ] && exit 0

# OSC 0: set both icon and window title. Write to controlling tty.
printf '\033]0;%s\007' "$TITLE" > /dev/tty 2>/dev/null || true

exit 0

#!/bin/bash
# PostToolUse hook: increment tool call counter per session
# Zero token cost — pure shell, no Claude involvement
# Reads session_id from stdin JSON to isolate per-session counts
SESSION_ID=$(jq -r '.session_id // "default"' 2>/dev/null)
COUNTER_FILE="/tmp/claude_skill_counter_${SESSION_ID}"

if [ ! -f "$COUNTER_FILE" ]; then
  echo 1 > "$COUNTER_FILE"
else
  count=$(($(cat "$COUNTER_FILE") + 1))
  echo $count > "$COUNTER_FILE"
fi

# Suppress output to avoid injecting anything into context
echo '{"suppressOutput": true}'

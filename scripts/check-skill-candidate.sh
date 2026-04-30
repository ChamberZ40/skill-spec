#!/bin/bash
# Stop hook: only inject prompt when tool calls exceed threshold
# If below threshold → outputs nothing (0 tokens added to context)
# If above → injects a short suggestion via hookSpecificOutput
THRESHOLD=${SKILL_CANDIDATE_THRESHOLD:-15}

SESSION_ID=$(jq -r '.session_id // "default"' 2>/dev/null)
COUNTER_FILE="/tmp/claude_skill_counter_${SESSION_ID}"

if [ ! -f "$COUNTER_FILE" ]; then
  exit 0
fi

count=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
rm -f "$COUNTER_FILE"

if [ "$count" -ge "$THRESHOLD" ]; then
  cat <<EOF
{"hookSpecificOutput": {"hookEventName": "Stop", "additionalContext": "[skill-lifecycle] Session used ${count} tool calls. If this was a multi-step repeatable task, suggest creating a skill to the user in 1 sentence."}}
EOF
fi

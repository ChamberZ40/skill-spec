#!/bin/bash
# PostToolUse hook: log tool call (append-only, atomic)
# Zero token cost — pure shell, no Claude involvement
# Fix: use append instead of read-modify-write to avoid race condition with async hooks
if ! command -v jq > /dev/null 2>&1; then
  echo '{"suppressOutput": true}'
  exit 0
fi

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "default"' 2>/dev/null)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)

COUNTER_FILE="/tmp/claude_skill_counter_${SESSION_ID}"
TOOLS_FILE="/tmp/claude_skill_tools_${SESSION_ID}"

# Append sentinel line (atomic, no race condition)
echo "x" >> "$COUNTER_FILE"

# Log tool name only if not already recorded (keeps file small)
if [ -n "$TOOL_NAME" ] && [ "$TOOL_NAME" != "null" ]; then
  grep -qxF "$TOOL_NAME" "$TOOLS_FILE" 2>/dev/null || echo "$TOOL_NAME" >> "$TOOLS_FILE"
fi

echo '{"suppressOutput": true}'

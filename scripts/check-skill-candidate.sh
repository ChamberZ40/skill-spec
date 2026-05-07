#!/bin/bash
# Stop hook: log candidate to data/candidates.md when threshold exceeded
# Pure shell — 0 token cost. Claude only involved at review time.
if ! command -v jq > /dev/null 2>&1; then
  exit 0
fi

THRESHOLD=${SKILL_CANDIDATE_THRESHOLD:-15}
SKILL_DIR="$HOME/.claude/skills/skill-spec"
CANDIDATES_FILE="$SKILL_DIR/data/candidates.md"

INPUT=$(cat /dev/stdin 2>/dev/null || echo '{}')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "default"' 2>/dev/null)

COUNTER_FILE="/tmp/claude_skill_counter_${SESSION_ID}"
TOOLS_FILE="/tmp/claude_skill_tools_${SESSION_ID}"

if [ ! -f "$COUNTER_FILE" ]; then
  exit 0
fi

# Count lines (each line = one tool call, atomic append from PostToolUse)
count=$(wc -l < "$COUNTER_FILE" | tr -d ' ')

# Read tools before cleanup
if [ -f "$TOOLS_FILE" ]; then
  tools=$(tr '\n' ',' < "$TOOLS_FILE" | sed 's/,$//')
  unique_count=$(wc -l < "$TOOLS_FILE" | tr -d ' ')
else
  tools="unknown"
  unique_count=0
fi

# Cleanup temp files (early delete prevents duplicate entries on re-trigger)
rm -f "$COUNTER_FILE" "$TOOLS_FILE"

if [ "$count" -ge "$THRESHOLD" ]; then
  date_str=$(date +%Y-%m-%d)

  # Ensure candidates file exists
  if [ ! -f "$CANDIDATES_FILE" ]; then
    echo "# Skill Candidates" > "$CANDIDATES_FILE"
    echo "" >> "$CANDIDATES_FILE"
  fi

  # Dedup: skip if this session is already logged
  if ! grep -q "Session:** ${SESSION_ID}" "$CANDIDATES_FILE" 2>/dev/null; then
    cat >> "$CANDIDATES_FILE" << ENTRY

## ${date_str} | ${count} calls | ${unique_count} tool types
- **Session:** ${SESSION_ID}
- **Tools:** ${tools}
- **Status:** pending
ENTRY
  fi

  # Emit systemMessage
  cat << EOF
{"systemMessage": "[skill-spec] Session logged to candidates (${count} calls, ${unique_count} tools). If this was repeatable work, consider running /skill-spec to review."}
EOF
fi

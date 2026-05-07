#!/bin/bash
# Setup hooks for skill-spec auto-detection
# Run this after installing via: npx skills add ChamberZ40/skill-spec
set -e

SETTINGS_FILE="$HOME/.claude/settings.json"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v jq > /dev/null 2>&1; then
  echo "❌ jq is required. Install: brew install jq (macOS) or apt install jq (Linux)"
  exit 1
fi

if [ ! -f "$SETTINGS_FILE" ]; then
  mkdir -p "$(dirname "$SETTINGS_FILE")"
  echo '{}' > "$SETTINGS_FILE"
fi

# Check if already configured
if jq -e '.hooks.PostToolUse // [] | .[].hooks // [] | .[].command // "" | select(contains("skill-spec"))' "$SETTINGS_FILE" > /dev/null 2>&1; then
  echo "✓ Hooks already configured"
  exit 0
fi

# Add hooks
jq '.hooks.PostToolUse = ((.hooks.PostToolUse // []) + [{
  "matcher": "",
  "hooks": [{"type": "command", "command": "~/.claude/skills/skill-spec/scripts/count-tool-use.sh", "timeout": 5, "async": true}]
}])' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"

jq '.hooks.Stop = ((.hooks.Stop // []) + [{
  "matcher": "",
  "hooks": [{"type": "command", "command": "~/.claude/skills/skill-spec/scripts/check-skill-candidate.sh", "timeout": 5}]
}])' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"

chmod +x "$SKILL_DIR/scripts/"*.sh 2>/dev/null || true

echo "✓ Hooks configured in $SETTINGS_FILE"
echo "  Auto-detection is now active."

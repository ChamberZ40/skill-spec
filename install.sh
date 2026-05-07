#!/bin/bash
# skill-spec installer — one command to set up everything
# Usage: curl -sSL https://raw.githubusercontent.com/ChamberZ40/skill-spec/main/install.sh | bash
set -e

REPO="https://github.com/ChamberZ40/skill-spec.git"
INSTALL_DIR="$HOME/.claude/skills/skill-spec"
SETTINGS_FILE="$HOME/.claude/settings.json"

echo "⚡ skill-spec installer"
echo ""

# 1. Check prerequisites
if ! command -v jq > /dev/null 2>&1; then
  echo "❌ jq is required but not installed."
  echo "   Install: brew install jq (macOS) or apt install jq (Linux)"
  exit 1
fi

if ! command -v git > /dev/null 2>&1; then
  echo "❌ git is required but not installed."
  exit 1
fi

# 2. Clone or update
if [ -d "$INSTALL_DIR" ]; then
  echo "→ Updating existing installation..."
  git -C "$INSTALL_DIR" pull --quiet
else
  echo "→ Installing to $INSTALL_DIR..."
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone --quiet "$REPO" "$INSTALL_DIR"
fi
chmod +x "$INSTALL_DIR/scripts/"*.sh
echo "✓ Files installed"

# 3. Configure hooks in settings.json
echo "→ Configuring hooks..."

if [ ! -f "$SETTINGS_FILE" ]; then
  mkdir -p "$(dirname "$SETTINGS_FILE")"
  echo '{}' > "$SETTINGS_FILE"
fi

# Merge hooks into existing settings without clobbering
HOOK_COUNT=$(jq -r '.hooks.PostToolUse // [] | length' "$SETTINGS_FILE")
ALREADY_INSTALLED=$(jq -r '.hooks.PostToolUse // [] | .[].hooks // [] | .[].command // "" | select(contains("skill-spec"))' "$SETTINGS_FILE")

if [ -n "$ALREADY_INSTALLED" ]; then
  echo "✓ Hooks already configured (skipped)"
else
  # Add PostToolUse hook
  jq '.hooks.PostToolUse = ((.hooks.PostToolUse // []) + [{
    "matcher": "",
    "hooks": [{"type": "command", "command": "~/.claude/skills/skill-spec/scripts/count-tool-use.sh", "timeout": 5, "async": true}]
  }])' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"

  # Add Stop hook
  jq '.hooks.Stop = ((.hooks.Stop // []) + [{
    "matcher": "",
    "hooks": [{"type": "command", "command": "~/.claude/skills/skill-spec/scripts/check-skill-candidate.sh", "timeout": 5}]
  }])' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"

  echo "✓ Hooks added to $SETTINGS_FILE"
fi

# 4. Verify
echo "→ Verifying..."
OUTPUT=$(echo '{"session_id":"install-test","tool_name":"Bash"}' | "$INSTALL_DIR/scripts/count-tool-use.sh")
rm -f /tmp/claude_skill_counter_install-test /tmp/claude_skill_tools_install-test

if [ "$OUTPUT" = '{"suppressOutput": true}' ]; then
  echo "✓ Hooks working correctly"
else
  echo "⚠ Unexpected output: $OUTPUT"
  echo "  Installation completed but hooks may not work correctly."
  exit 1
fi

echo ""
echo "🎉 skill-spec installed successfully!"
echo ""
echo "   What happens now:"
echo "   • Hooks run silently on every Claude Code session"
echo "   • Complex sessions (15+ tool calls) get logged as candidates"
echo "   • Run /skill-spec to review candidates when ready"
echo ""
echo "   Config: set SKILL_CANDIDATE_THRESHOLD in settings.json env to adjust"

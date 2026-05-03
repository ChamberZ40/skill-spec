# skill-spec

> Treat your AI skills like production specs — version them, review them, ship them.

## What is this?

A methodology + toolchain for engineering Claude Code skills with rigor. Instead of writing skills once and forgetting them, `skill-spec` gives you:

- **Auto-detection** — Hooks that silently track tool calls + tool diversity, surfacing skill candidates at session end
- **Scaffold** — Template-based skill creation from candidates
- **Tiered change management** — Patch (direct edit) vs Proposal (CHANGE.md with review gates)
- **Composition** — Chain skills into workflows via a dependency registry

## The Problem

You just spent 45 minutes and 20+ tool calls doing something complex with Claude. Tomorrow you'll do it again from scratch. Next week, same thing.

Skills solve this — but:
1. How do you know **when** to create one?
2. How do you **iterate** without breaking what works?
3. How do you **connect** skills into larger workflows?

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                    Session Running                            │
│                                                              │
│  PostToolUse hook (async, 0 tokens)                          │
│  └─ Increments counter + logs tool_name to /tmp              │
│                                                              │
│  Stop hook                                                   │
│  └─ If counter >= threshold:                                 │
│       • Write candidate to data/candidates.md (pure shell)   │
│       • Inject 1-sentence prompt (~30 tokens)                │
│     Else:                                                    │
│       silent exit (0 tokens)                                 │
└─────────────────────────────────────────────────────────────┘
         │
         ▼ candidates accumulate
┌─────────────────────────────────────────────────────────────┐
│  /skill-spec review                                          │
│  └─ Claude reads candidates.md                               │
│  └─ Evaluates: multi-step? repeatable?                       │
│  └─ YES → scaffold from template                            │
│  └─ NO  → mark skipped                                      │
└─────────────────────────────────────────────────────────────┘
```

## Installation

### 1. Clone to your Claude Code skills directory

```bash
git clone https://github.com/ChamberZ40/skill-spec.git ~/.claude/skills/skill-spec
```

### 2. Add hooks to `~/.claude/settings.json`

Merge these into your existing settings (don't replace the whole file):

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/skills/skill-spec/scripts/count-tool-use.sh",
            "timeout": 5,
            "async": true
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/skills/skill-spec/scripts/check-skill-candidate.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

### 3. Verify installation

```bash
# Test the hooks work
echo '{"session_id": "test", "tool_name": "Bash"}' | ~/.claude/skills/skill-spec/scripts/count-tool-use.sh
# Should output: {"suppressOutput": true}
```

### 4. (Optional) Adjust threshold

Default is 15 tool calls. Override via env in settings.json:

```json
{
  "env": {
    "SKILL_CANDIDATE_THRESHOLD": "20"
  }
}
```

## Token Cost

| Session complexity | Extra tokens consumed |
|---|---|
| Simple (< 15 tool calls) | **0** |
| Complex (>= 15 tool calls) | **~30** (one sentence injected at session end) |

The PostToolUse hook is `async: true` and outputs `{"suppressOutput": true}` — it never touches your context window.

## The Four Phases

### Phase 1: Detection

Hooks track two signals per session (zero token cost):
- **Total tool calls** — raw complexity indicator
- **Unique tool types** — diversity indicator (Bash+Edit+Write+Agent = more complex than 20x Read)

When threshold exceeded, a candidate is logged to `data/candidates.md`:
```markdown
## 2026-05-03 | 23 calls | 6 tool types
- **Session:** abc123
- **Tools:** Bash,Edit,Write,Agent,WebFetch,Read
- **Status:** pending
```

### Phase 2: Scaffold

When you review candidates and confirm one is worth keeping:
- Claude uses `templates/SKILL.template.md` to generate a new skill directory
- Pre-fills steps based on what was observed in the session

### Phase 3: Change Management (Tiered)

| Level | When | Process |
|-------|------|---------|
| **Patch** | Won't surprise users (typo, wording, edge case) | Direct edit + git commit |
| **Proposal** | Changes behavior (add/remove steps, reorder) | CHANGE.md entry → user review |

**Rule of thumb:** If someone using this skill would say "huh?" — it needs a proposal.

### Phase 4: Composition

Register skill dependencies in `data/chains.md`:

```
[publisher-matcher] --{matched list}--> [publisher-review]
[publisher-review] --{confirmed list}--> [email-generator]
[email-generator] --{email content}--> [mail-send-batch]
```

Each skill's `## Next Steps` section tells Claude what to suggest after execution.

## File Structure

```
~/.claude/skills/skill-spec/
├── SKILL.md                        # Methodology (loaded into Claude context)
├── scripts/
│   ├── count-tool-use.sh           # PostToolUse — async counter + tool log
│   └── check-skill-candidate.sh    # Stop — threshold check + candidate writer
├── data/
│   ├── candidates.md               # Auto-populated candidate log
│   └── chains.md                   # Skill dependency registry
└── templates/
    └── SKILL.template.md           # Scaffold for new skills
```

## Usage

### Passive mode (default)
Just use Claude Code normally. Hooks run silently. Candidates accumulate.

### Review mode
```
You: /skill-spec
Claude: [reads candidates.md, evaluates each pending entry]
```

### Register a chain
```
You: Register the email pipeline chain in skill-spec
Claude: [updates data/chains.md with the dependency graph]
```

## Prerequisites

- Claude Code CLI
- `jq` installed (for JSON parsing in hooks)
- Bash-compatible shell

## Philosophy

Skills are specs. Specs need:
- **Observability** — Hooks that surface when a new spec is needed
- **Scaffolding** — Templates that reduce friction to create
- **Tiered governance** — Light touch for small changes, review gates for big ones
- **Composability** — Skills that chain into workflows

Write once, iterate forever.

## License

MIT

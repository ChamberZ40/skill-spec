# skill-spec

> Treat your AI skills like production specs — version them, review them, ship them.

## What is this?

A methodology + toolchain for engineering Claude Code skills with rigor. Instead of writing skills once and forgetting them, `skill-spec` gives you:

- **Auto-detection** — Hooks that silently count tool calls and surface skill candidates at session end
- **Change management** — Numbered proposals (`CHANGE.md`) with status tracking and human review gates
- **Composition** — A framework for chaining skills into workflows

## The Problem

You just spent 45 minutes and 20+ tool calls doing something complex with Claude. Tomorrow you'll do it again from scratch. Next week, same thing.

Skills solve this — but:
1. How do you know **when** to create one?
2. How do you **iterate** without breaking what works?
3. How do you **connect** skills into larger workflows?

## How It Works

```
┌─────────────────────────────────────────────────────────┐
│                    Session Running                        │
│                                                          │
│  PostToolUse hook (async)                                │
│  └─ Increments counter in /tmp (0 tokens, pure shell)   │
│                                                          │
│  Stop hook                                               │
│  └─ If counter >= threshold:                             │
│       inject 1-sentence suggestion (~30 tokens)          │
│     Else:                                                │
│       silent exit (0 tokens)                             │
└─────────────────────────────────────────────────────────┘
         │
         ▼ skill candidate identified
┌─────────────────────────────────────────────────────────┐
│  Phase 1: Create SKILL.md                                │
│  Phase 2: Iterate via CHANGE.md proposals                │
│  Phase 3: Chain with downstream skills                   │
└─────────────────────────────────────────────────────────┘
```

## Installation

### 1. Copy skill to your Claude Code skills directory

```bash
git clone git@github.com:ChamberZ40/skill-spec.git ~/.claude/skills/skill-spec
```

### 2. Add hooks to `~/.claude/settings.json`

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

### 3. (Optional) Adjust threshold

Default is 15 tool calls. Override via env:

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

## The Three Phases

### Phase 1: Identification

A skill candidate must satisfy ALL of:
- >= 3 rounds of conversation
- >= 3 distinct steps
- Will recur in the future

The hook automates the first signal. You decide the rest.

### Phase 2: Change Management

Don't edit `SKILL.md` directly. Create proposals in `CHANGE.md`:

```markdown
## #001 - Add retry logic for API failures
- **Status:** proposed
- **Date:** 2026-04-30
- **Trigger:** Skill failed silently when API returned 429
- **Proposal:** Add exponential backoff step between API calls
- **Impact:** Adds ~10s to execution, prevents silent failures
```

Status flow: `proposed` → `accepted` → `implemented` (or `rejected` with reason)

### Phase 3: Composition

After a skill runs, ask:
- Does its output feed another skill? → Link them
- Is there always a next step? → Add `## Next Steps`
- Do multiple skills always run together? → Create an orchestration skill

## File Structure

```
~/.claude/skills/skill-spec/
├── SKILL.md                        # The methodology (loaded by Claude Code)
└── scripts/
    ├── count-tool-use.sh           # PostToolUse hook — async counter
    └── check-skill-candidate.sh    # Stop hook — threshold check
```

## Philosophy

Skills are specs. Specs need:
- **Versioning** — CHANGE.md with numbered proposals
- **Review gates** — Human approval before changes land
- **Observability** — Hooks that surface when a new spec is needed
- **Composability** — Skills that chain into workflows

Write once, iterate forever.

## License

MIT

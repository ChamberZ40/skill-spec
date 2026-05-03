---
name: skill-spec
description: Use when identifying skill candidates from repeated work, managing skill change proposals, reviewing candidates, or chaining skills into workflows. Also invoke directly to scaffold a new skill or review accumulated candidates.
---

# Skill Spec Engineering

## Overview

Skill 是需要持续迭代的 spec 工程。本方法论覆盖完整生命周期：自动检测 → 候选记录 → 脚手架创建 → 变更管理 → 下游串联。

## Phase 1: Detection — 自动候选识别

### Hook 驱动（0 token）

- **PostToolUse**（async）— 递增计数器 + 记录工具名称，纯 shell
- **Stop** — 超阈值时写入 `data/candidates.md`，注入一句提示（~30 token）

阈值默认 15，环境变量覆盖：`SKILL_CANDIDATE_THRESHOLD=20`

### 候选记录格式

自动写入 `data/candidates.md`：
```markdown
## 2026-05-03 | 23 calls | 6 tool types
- **Session:** abc123
- **Tools:** Bash,Edit,Write,Agent,WebFetch,Read
- **Status:** pending
```

### Review 模式

用户主动调用时，读取 candidates.md，对每个 pending 条目：
1. 回溯 session 内容生成关键步骤摘要
2. 评估是否满足三条件（多步、多轮、可重复）
3. 满足 → 用模板脚手架创建 skill；不满足 → 标记 skipped

## Phase 2: Scaffold — 脚手架创建

满足条件的候选，使用 `templates/SKILL.template.md` 生成：

```bash
~/.claude/skills/[new-skill-name]/
├── SKILL.md        # 从模板生成，预填步骤
└── CHANGE.md       # 空，准备接收提案
```

## Phase 3: Change Management — 分级变更

### 两级制度

| 级别 | 判断标准 | 流程 |
|------|----------|------|
| **Patch** | 不会让使用者感到意外（措辞、typo、补充边界条件） | 直接改 + git commit |
| **Proposal** | 会改变 skill 行为（增删步骤、改顺序、改逻辑） | CHANGE.md 提案 → 用户 review |

**一句话判断：** 如果这个改动会让正在用 skill 的人说"咦？"，那就需要 proposal。

### Proposal 格式

```markdown
## #001 - [标题]
- **Status:** proposed | accepted | rejected | implemented
- **Date:** 2026-05-03
- **Trigger:** 什么场景触发了修改需求
- **Proposal:** 具体修改 + 原因
- **Breaking?:** yes/no
```

## Phase 4: Composition — 下游串联

### Next Steps 格式（写在每个 skill 末尾）

```markdown
## Next Steps
- **If [具体条件]**: invoke [skill-name] — [一句话原因]
- **If [另一条件]**: invoke [another-skill] — [原因]
```

### Chains 注册表

`data/chains.md` 记录 skill 间的输入输出关系：

```
[publisher-matcher] --{匹配结果}--> [publisher-review]
[publisher-review] --{确认列表}--> [email-generator]
[email-generator] --{邮件内容}--> [mail-send-batch]
```

当一个 skill 执行完，检查 chains.md 是否有下游 → 提示用户。

## Quick Reference

| 阶段 | 触发 | Token 开销 | 产物 |
|------|------|-----------|------|
| Detection | 每个 session 自动 | 0（shell）| data/candidates.md |
| Scaffold | 用户确认候选 | 按需 | 新 skill 目录 |
| Change | 使用中发现问题 | 0 | CHANGE.md 或直接 commit |
| Composition | skill 执行完毕 | 按需 | Next Steps / chains.md |

## Common Mistakes

- **把 patch 当 proposal** — 改个措辞不需要走提案，直接改
- **候选堆积不 review** — 定期清理 candidates.md，否则失去参考价值
- **串联写得太模糊** — Next Steps 必须包含具体条件，不能写"如果需要可以用 X"
- **模板当作终稿** — 脚手架只是起点，生成后必须根据实际情况调整

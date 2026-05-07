# skill-spec

> 你的 AI 不会忘记代码，为什么要忘记流程？

[English](./README.md)

**skill-spec** 自动将你 Claude Code 会话中隐藏的工作模式转化为可版本化、可迭代、可组合的 spec。

---

## 快速开始

```bash
# 1. 安装
git clone https://github.com/ChamberZ40/skill-spec.git ~/.claude/skills/skill-spec

# 2. 在 ~/.claude/settings.json 中添加 hooks（合并，不要覆盖整个文件）
```

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "",
      "hooks": [{"type": "command", "command": "~/.claude/skills/skill-spec/scripts/count-tool-use.sh", "timeout": 5, "async": true}]
    }],
    "Stop": [{
      "matcher": "",
      "hooks": [{"type": "command", "command": "~/.claude/skills/skill-spec/scripts/check-skill-candidate.sh", "timeout": 5}]
    }]
  }
}
```

```bash
# 3. 验证安装
echo '{"session_id":"test","tool_name":"Bash"}' | ~/.claude/skills/skill-spec/scripts/count-tool-use.sh
# → {"suppressOutput": true}

# 4. 完成。正常使用 Claude Code，候选会静默积累。
```

---

## 核心理念

每次 20+ 工具调用的 session 都是一个等待被捕获的流程。但你从不停下来记录，因为：

- 直到第 3 次才意识到这是重复模式
- 从零写一个 skill 有阻力
- 已有的 skill 因为没有变更管理而逐渐腐化

**skill-spec** 以零额外成本解决这三个问题：

```
Session 结束 → hook 触发 → 候选记录 → 你决定何时 review → skill 诞生（或已有 skill 被增强）
```

**日常工作零 token 消耗。** 整个检测层是纯 shell。

---

## 工作流程

```
                        你的日常工作
                              │
         ┌────────────────────┼────────────────────┐
         │                    │                    │
         │   PostToolUse      │   Stop hook        │
         │   (异步, 0 tok)    │   (超阈值?)        │
         │   计数 + 记录      │                    │
         │                    │   < 15 → 静默      │
         │                    │   >= 15 → 记录     │
         └────────────────────┼────────────────────┘
                              │
                              ▼
                   data/candidates.md
                   （静默积累）
                              │
                              ▼  当你决定 review 时
              ┌───────────────────────────────────┐
              │       /skill-spec review           │
              │                                   │
              │  对每个候选:                        │
              │  1. 可重复吗?                      │
              │  2. 已有类似 skill?                │
              │     是 → 创建提案                  │
              │     否 → 脚手架新 skill            │
              └───────────────────────────────────┘
```

---

## 四个阶段

### 1. 检测（自动，0 token）

两个 shell hook 在每个 session 运行：
- **PostToolUse** — 计数 + 记录使用了哪些工具
- **Stop** — 超过阈值时写入候选条目

你不会感知到它。它只是静默运行。

### 2. 脚手架（按需，带查重）

当你 review 候选时：
1. 扫描已有 skill 检查是否重复
2. **有匹配** → 在已有 skill 的 CHANGE.md 创建提案（避免重复）
3. **无匹配** → 从模板生成新 skill 目录

永远不会有重复的 skill。

### 3. 变更管理（分级）

| | Patch | Proposal |
|---|---|---|
| **什么情况** | 改措辞、修 typo、补边界条件 | 增删步骤、改顺序、改行为 |
| **流程** | 直接改 + commit | CHANGE.md → 用户 review → 实施 |
| **判断标准** | 用户会注意到吗？不会 → patch | 用户会说"等等？" → proposal |

### 4. 组合

Skill 声明下游连接关系：
```
[skill-A] --{输出}--> [skill-B] --{输出}--> [skill-C]
```

Skill 执行完后，Claude 检查是否有下游建议。

---

## Token 消耗

| 场景 | 消耗 |
|------|------|
| 普通 session (< 15 次调用) | **0** |
| 复杂 session (>= 阈值) | session 结束时 **~30 token** |
| Skill 加载到上下文 | **~700 token**（仅被触发时） |
| Skill 列表中的描述 | **~40 token**（所有 skill 都一样） |

检测层不可见。在你主动 review 之前不花费任何代价。

---

## 前置要求

- Claude Code CLI
- `jq`（hook 中的 JSON 解析）
- Bash 兼容 shell

---

## 配置

| 变量 | 默认值 | 作用 |
|------|--------|------|
| `SKILL_CANDIDATE_THRESHOLD` | `15` | 触发候选记录的最小工具调用数 |

在 `~/.claude/settings.json` 的 `"env"` 中设置。

---

## 哲学

> Skill 即 Spec。Spec 需要工程化。

- **观测** — 检测何时需要新的 spec
- **去重** — 增强已有 spec 而不是创建克隆
- **治理** — 小改动轻触达，大改动走审批
- **组合** — spec 串联成流水线

目标不是更多 skill，而是更好的 skill，持续改进。

---

## 许可证

MIT

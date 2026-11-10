# 使用场景

## 该用哪个技能

| 你手上有 | 用 | 会发生什么 |
| --- | --- | --- |
| 一个任务、问题或粗略想法，还没有方案 | `/native-routed-cc <任务>` | 主会话根据 worker 的探索结果定方案，再派发实现和审查 |
| 已经定好的方案、一份 spec 或一张票据 | `/native-implement-routed-cc <方案或票据>` | 先写测试、审查、提交，worker 实现，reviewer 审查 |
| 拆成票据、带阻塞关系的 spec | `/native-implement-spec-routed-cc <spec>` | 就绪的票据在各自的 worktree 里并行实现，合到一条集成分支，最后统一审查 |
| 同时跑着好几个 routed 会话，记不住各自进展 | `/native-watch-cc start` | 当前会话里的定时任务巡检已登记的运行，只报变化，给每个待决策项重建背景，并转达你的决定。`/native-watch-cc stop` 结束 |
| 想换模型，或者某处坏了 | `/native-routed-setup-cc` | 检测、给出模型建议、你确认后写入、复检。`/native-routed-setup-cc check` 只出报告 |

做一个功能的常见路径：先讨论或 grill 想法 → `to-spec` → `to-tickets` → `/native-implement-spec-routed-cc`。单个改动：在对话里定好方案 → `/native-implement-routed-cc`。

## 角色

- **主会话**负责设计和编排。它不自己探索、调研或实现任务，也不把方案设计交给别的代理。
- **worker** 负责探索、调研、实现、合并，以及修复审查发现的问题。
- **reviewer** 只读审查，诊断疑难失败。它不审查自己写的代码。
- **委员会**：同一个失败出现第二次时召集的两个只读子代理，一个深挖根因，一个质疑现有方案。

这些角色都是用 Claude Code 的 Agent 工具起的子代理。

## 模型

| 角色 | 默认 | 怎么改 |
| --- | --- | --- |
| worker | 宿主的子代理默认模型（设了 `CLAUDE_CODE_SUBAGENT_MODEL` 就用它） | 配置里的 `cc.worker`，或 `--worker <模型>` |
| reviewer | `opus` | `cc.reviewer`，或 `--reviewer <模型>` |
| 委员会 | `opus` 和 `fable` | `cc.committee` |

配置文件是 `~/.native-routed/config.yaml`，由 `/native-routed-setup-cc` 写入。取值是 Agent 工具的 `model` 参数接受的值。显式传的 `model` 会覆盖 `CLAUDE_CODE_SUBAGENT_MODEL`，reviewer 就是靠这一点用上比 worker 更强的模型。

## 常见问题

**和 paseo-routed 有什么区别？** 不需要 Paseo daemon、profile 和 roster：角色都是 Claude Code 的子代理，模型由一份很小的配置决定。代价是子代理随主会话结束，审查也不能换别的外壳来做。

**笔记放在哪？** `~/.native-routed/notes/<主题>/`，在仓库外面。所有子代理都能读，也不会被提交进仓库。里面的 `session.json` 让 `native-watch-cc` 能找到这次运行。

**reviewer 能写文件吗？** 工具层面能。审查简报会写明只读，每次审查完主会话都会检查 `git status`。

**跑到一半停了。** 说“继续”。子代理活不过重启，主会话会读笔记，检查各个 worktree 的 `git log` 和 `git status`，再把没做完的重新派出去。

**同一个失败反复出现。** 第二次出现时，主会话会召集委员会做独立的根因分析，不让实现者原地重试。

**watch 不汇报了。** 它的定时任务只活在负责巡检的那个会话里，只在会话空闲时触发，7 天后过期。重新跑一次 `/native-watch-cc start`。

# 使用场景

## 该用哪个技能

| 你手上有 | 用 | 会发生什么 |
| --- | --- | --- |
| 一个任务、问题或粗略想法，还没有方案 | `/paseo-routed <任务>` | 主会话根据 worker 的探索结果定方案，再派发实现和审查 |
| 已经定好的方案、一份 spec 或一张票据 | `/implement-routed <方案或票据>` | 按 `implement` 的流程走（先写测试、审查、提交），worker 实现，reviewer 审查 |
| 拆成票据、带阻塞关系的 spec | `/implement-spec-routed <spec>` | 按 `implement-spec` 的流程走：就绪的票据在各自的 worktree 里并行实现，合到一条集成分支，最后统一审查 |
| 同时跑着好几个编排者，记不住各自进展 | `/paseo-watch start` | Paseo heartbeat 定时巡检顶层编排者，只报变化，给每个待决策项重建背景，并转达你的决定。`/paseo-watch stop` 结束 |
| 还没配置，或者某处坏了 | `/setup-paseo-routed` | 检测、出方案、你确认后写入、复检。`/setup-paseo-routed check` 只出报告 |

做一个功能的常见路径：先讨论或 grill 想法 → `to-spec` → `to-tickets` → `/implement-spec-routed`。单个改动：在对话里定好方案 → `/implement-routed`。

## 角色

- **主会话**负责设计和编排。它不自己探索、调研或实现任务，也不把方案设计交给别的代理。
- **worker** 负责探索、调研、实现、合并，以及修复审查发现的问题。
- **reviewer** 只读审查，诊断疑难失败。它不审查自己写的代码。

## Roster

roster 规定每个角色由哪个 Paseo profile 来做，配置在 `~/.paseo-routed/config.yaml`：

```yaml
default_roster: main
rosters:
  main: { worker: Builder, reviewer: Critic }
  alt:  { worker: Builder-alt, reviewer: Critic-alt, compare: true }
```

- 单次换一套：`/paseo-routed --roster alt <任务>`，或者直接说“用 alt 阵容”。
- 长期换：改 `default_roster`。
- 想试新模型：给它建一个 Paseo profile，再加一行 roster，技能不用改。
- 对比不同 roster：设 `compare: true`，每次运行会把返工轮数和审查发现数记到共享笔记里。
- 想要 `/paseo-routed-alt` 这种个人快捷命令：在本地建一个技能，正文写“用 --roster alt 执行 paseo-routed 技能，参数是 $ARGUMENTS”。不要放进共享仓库。

## 常见问题

**为什么不用宿主自带的 subagent？** Paseo 代理按你选的 profile 运行，有自己的 worktree，主会话结束了也还在，审查还可以换一个模型或外壳来做。这套技能不会悄悄退回自带 subagent，找不到 profile 就停下来告诉你。

**笔记放在哪？** `<notes_dir>/<主题>/`，在仓库外面。所有代理都能读，也不会被提交进仓库。

**reviewer 的 profile 有写权限，会出问题吗？** 审查简报会写明只读，每次审查完主会话都会检查 `git status`。

**跑到一半停了。** 说“继续”。主会话会先列出还在运行的代理，检查各个 worktree 的 `git log` 和 `git status`，再往下做。

**同一个失败反复出现。** 第二次出现时，主会话会调用 `paseo-committee` 做独立的根因分析，不让实现者原地重试。

**提示缺少 profile 或 roster。** 运行会停下并指出缺的是哪个。跑一次 `/setup-paseo-routed`。

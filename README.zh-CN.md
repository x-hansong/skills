# skills

[x-hansong](https://github.com/x-hansong) 维护的 Agent 技能，支持 Claude Code 和 Codex，用 [skills CLI](https://skills.sh/docs) 安装。

[English](README.md)

## Paseo Routed

方案设计和编排留在你的主会话里，具体工作交给 [Paseo](https://paseo.sh) 代理：**worker** 负责探索、调研、实现和合并，另一个 **reviewer** 负责审查和诊断。两个角色分别用哪个 Paseo profile，由 **roster** 决定，每次运行都可以换。想试别的模型或外壳，改配置就行，不用新写技能。

| 技能 | 谁来调用 | 用途 |
| --- | --- | --- |
| [`setup-paseo-routed`](skills/paseo-routed/setup-paseo-routed/SKILL.md) | 你 | 首次配置和体检：检测已有配置，只补缺的部分，你确认后才写入 |
| [`paseo-routed-guide`](skills/paseo-routed/paseo-routed-guide/SKILL.md) | 你或模型 | 该用哪个技能、roster 怎么用、带你跑第一次 |
| [`paseo-routed`](skills/paseo-routed/paseo-routed/SKILL.md) | 你或模型 | 任意任务：主会话定方案，worker 探索和实现，reviewer 审查 |
| [`implement-routed`](skills/paseo-routed/implement-routed/SKILL.md) | 你 | 已定的方案、spec 或单张票据，按 `implement` 的流程走 |
| [`implement-spec-routed`](skills/paseo-routed/implement-spec-routed/SKILL.md) | 你 | 带票据依赖图的 spec，按 `implement-spec` 的流程走 |
| [`paseo-watch`](skills/paseo-routed/paseo-watch/SKILL.md) | 你 | 同时跑着很多编排者时用：heartbeat 定时汇报变化，标出停摆的编排者和缓存快失效的待决策项，给每个待决策项重建背景，再把你的决定转达回去 |

### 依赖

- [Paseo](https://paseo.sh) CLI，daemon 要在运行：`npm install -g @getpaseo/cli`
- Paseo 自带的编排技能：`npx skills add getpaseo/paseo`
- 两个 implement 技能还需要 [mattpocock/skills](https://github.com/mattpocock/skills) 里的 `implement`、`implement-spec`、`tdd`、`code-review`

`setup-paseo-routed` 会逐项检查，并告诉你缺了什么。

### 安装

```bash
npx skills add x-hansong/skills -g -a claude-code -a codex \
  --skill setup-paseo-routed --skill paseo-routed-guide \
  --skill paseo-routed --skill implement-routed --skill implement-spec-routed \
  --skill paseo-watch
```

装好后，在 Claude Code 或 Codex 里运行：

```text
/setup-paseo-routed
```

### Roster

`~/.paseo-routed/config.yaml`：

```yaml
version: 1
default_roster: main
rosters:
  main: { worker: Builder, reviewer: Critic }
  alt:  { worker: Builder-alt, reviewer: Critic-alt, compare: true }
notes_dir: ~/.paseo-routed/notes
```

`/paseo-routed --roster alt <任务>` 只在这一次用 `alt`；要长期切换，改 `default_roster`。设了 `compare: true` 的 roster 会记录返工轮数和审查发现数，方便对比。

详细说明见[上手指南](docs/paseo-routed/getting-started.zh-CN.md)。

## Native Routed

同样的分工，但不依赖 Paseo，用的是各宿主自带的子代理。Claude Code 一套（`-cc`），Codex 一套（`-codex`），各自只在自己的宿主里运行，不互相调用。**worker** 子代理负责探索、实现和合并，**reviewer** 子代理用更强的模型做审查，同一个失败出现第二次时由两人**委员会**诊断。子代理随主会话结束，所以中断后从笔记和 git 恢复。

| 技能（`-cc` / `-codex`） | 谁来调用 | 用途 |
| --- | --- | --- |
| [`native-routed-setup-*`](skills/native-routed/native-routed-setup-cc/SKILL.md) | 你 | 选 worker、reviewer、委员会用的模型，以及体检。Codex 必须先跑一次 |
| [`native-routed-guide-*`](skills/native-routed/native-routed-guide-cc/SKILL.md) | 你或模型 | 该用哪个技能、模型怎么选、带你跑第一次 |
| [`native-routed-*`](skills/native-routed/native-routed-cc/SKILL.md) | 你或模型 | 任意任务：主会话定方案，worker 探索和实现，reviewer 审查 |
| [`native-implement-routed-*`](skills/native-routed/native-implement-routed-cc/SKILL.md) | 你 | 已定的方案、spec 或单张票据，按 `implement` 的流程走 |
| [`native-implement-spec-routed-*`](skills/native-routed/native-implement-spec-routed-cc/SKILL.md) | 你 | 带票据依赖图的 spec，按 `implement-spec` 的流程走 |
| [`native-watch-*`](skills/native-routed/native-watch-cc/SKILL.md) | 你 | 同时跑着很多 routed 会话时用：汇报变化，标出停摆的会话和缓存快失效的待决策项，给每个待决策项重建背景，再把你的决定转达回去 |

两个宿主的差别：

| | Claude Code | Codex |
| --- | --- | --- |
| 子代理 | Agent 工具；并行单元用 `isolation: "worktree"` | `spawn_agent`，传 `fork_turns: "none"`；worktree 由编排者创建 |
| 模型 | 有默认值：reviewer `opus`，委员会 `opus` + `fable`；配置可选 | 没有默认值；先跑一次 setup，从 `spawn_agent` 能选的模型里挑 |
| watch 巡检 | 巡检会话里的 `CronCreate` | Codex 应用里用 heartbeat 自动化；CLI 里手动 `now` |
| watch 转达 | `SendMessage` | `codex queue` |

### 依赖

- Claude Code；或开启了 `multi_agent` 特性的 Codex
- [mattpocock/skills](https://github.com/mattpocock/skills) 里的 `code-review`；两个 implement 技能还需要 `implement`、`implement-spec`、`tdd`

### 安装

每套只装到自己的宿主：

```bash
npx skills add x-hansong/skills -g -a claude-code \
  --skill native-routed-setup-cc --skill native-routed-guide-cc \
  --skill native-routed-cc --skill native-implement-routed-cc \
  --skill native-implement-spec-routed-cc --skill native-watch-cc

npx skills add x-hansong/skills -g -a codex \
  --skill native-routed-setup-codex --skill native-routed-guide-codex \
  --skill native-routed-codex --skill native-implement-routed-codex \
  --skill native-implement-spec-routed-codex --skill native-watch-codex
```

装好后，在 Claude Code 里运行 `/native-routed-setup-cc`，在 Codex 里运行 `$native-routed-setup-codex`。

### 模型

`~/.native-routed/config.yaml`，每个宿主一节，各自的 setup 只改自己那一节：

```yaml
version: 1
cc:
  reviewer: opus
  committee: [opus, fable]
codex:
  reviewer: { model: <strong-model>, effort: high }
  committee:
    - { model: <strong-model>, effort: high }
    - { model: <other-strong-model>, effort: high }
```

`--reviewer <模型>`（Codex 写成 `<模型>/<effort>`）只对这一次运行生效。

## 许可

[MIT](LICENSE)

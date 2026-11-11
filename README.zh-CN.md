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
| [`implement-routed`](skills/paseo-routed/implement-routed/SKILL.md) | 你 | 已定的方案、spec 或单张票据，先写测试，再审查、提交 |
| [`implement-spec-routed`](skills/paseo-routed/implement-spec-routed/SKILL.md) | 你 | 带票据依赖图的 spec：就绪的票据在各自的 worktree 里并行实现，合到一条集成分支，最后统一审查 |
| [`paseo-watch`](skills/paseo-routed/paseo-watch/SKILL.md) | 你 | 同时跑着很多编排者时用：heartbeat 定时汇报变化，标出停摆的编排者、探针盯着的后台任务停了的情况，以及缓存快失效的待决策项，给每个待决策项重建背景，再把你的决定转达回去 |

### 依赖

- [Paseo](https://paseo.sh) CLI，daemon 要在运行：`npm install -g @getpaseo/cli`
- Paseo 自带的编排技能：`npx skills add getpaseo/paseo`

`setup-paseo-routed` 会逐项检查，并告诉你缺了什么。

装一个技能时，把它会加载的技能一起装上：

| 技能 | 一起装 |
| --- | --- |
| `paseo-routed` | `paseo`、`paseo-advisor`、`paseo-committee`（Paseo 提供） |
| `implement-routed` | `paseo-routed` 及其依赖 |
| `implement-spec-routed` | `paseo-routed` 及其依赖 |
| `paseo-routed-guide` | `setup-paseo-routed`、`paseo-routed` |
| `setup-paseo-routed`、`paseo-watch` | 无 |

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
| [`native-implement-routed-*`](skills/native-routed/native-implement-routed-cc/SKILL.md) | 你 | 已定的方案、spec 或单张票据，先写测试，再审查、提交 |
| [`native-implement-spec-routed-*`](skills/native-routed/native-implement-spec-routed-cc/SKILL.md) | 你 | 带票据依赖图的 spec：就绪的票据在各自的 worktree 里并行实现，合到一条集成分支，最后统一审查 |
| [`native-watch-*`](skills/native-routed/native-watch-cc/SKILL.md) | 你 | 同时跑着很多 routed 会话时用：汇报变化，标出停摆的会话、探针盯着的后台任务停了的情况，以及缓存快失效的待决策项，给每个待决策项重建背景，再把你的决定转达回去 |

两个宿主的差别：

| | Claude Code | Codex |
| --- | --- | --- |
| 子代理 | Agent 工具；并行单元用 `isolation: "worktree"` | `spawn_agent`，传 `fork_turns: "none"`；worktree 由编排者创建 |
| 模型 | 有默认值：reviewer `opus`，委员会 `opus` + `fable`；配置可选 | 没有默认值；先跑一次 setup，从 `spawn_agent` 能选的模型里挑 |
| watch 巡检 | 巡检会话里的 `CronCreate` | Codex 应用里用 heartbeat 自动化；CLI 里手动 `now` |
| watch 转达 | `SendMessage` | `codex queue` |

### 依赖

- Claude Code；或开启了 `multi_agent` 特性的 Codex

装一个技能时，把它会加载的技能一起装上，且只用同一宿主的那套：

| 技能（`-cc` / `-codex`） | 一起装 |
| --- | --- |
| `native-implement-routed-*`、`native-implement-spec-routed-*` | `native-routed-*` |
| `native-routed-guide-*` | `native-routed-setup-*`、`native-routed-*` |
| `native-routed-*` | 无；Codex 要先用 `native-routed-setup-codex` 写好配置 |
| `native-watch-*` | 无；它盯的是 `native-routed-*` 和 implement 技能发起的运行 |
| `native-routed-setup-*` | 无 |

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
  budget: medium            # 可选：small | medium | large | unlimited
  reviewer: opus
  committee: [opus, fable]
codex:
  reviewer: { model: <strong-model>, effort: high }
  committee:
    - { model: <strong-model>, effort: high }
    - { model: <other-strong-model>, effort: high }
```

`budget` 统一设定没单独写 effort 的角色的推理强度；`committee` 列表有几项就起几个成员。`--reviewer <模型>[/<effort>]` 和 `--budget <档位>` 只对这一次运行生效。运行中模型起不来时按固定顺序降级，报告里会写明。

## 使用方法

下面的例子用 Paseo 版的命令名。用原生版时换成对应名字，Codex 里把开头的 `/` 换成 `$`：

| 做什么 | Paseo | Claude Code 原生 | Codex 原生 |
| --- | --- | --- | --- |
| 任意任务 | `/paseo-routed` | `/native-routed-cc` | `$native-routed-codex` |
| 按定好的方案实现 | `/implement-routed` | `/native-implement-routed-cc` | `$native-implement-routed-codex` |
| 按 spec 和票据并行实现 | `/implement-spec-routed` | `/native-implement-spec-routed-cc` | `$native-implement-spec-routed-codex` |
| 盯多个运行 | `/paseo-watch` | `/native-watch-cc` | `$native-watch-codex` |

先判断需求大小。一个分支、一两次提交能做完，验收标准一两句话说得清，就是小需求。要拆成几张有先后关系的票据、涉及好几个模块，或者需要先统一术语、留下设计决策，就按大需求走。

### 小需求

还没方案时用 `/paseo-routed`。主会话先派 worker 探索代码，据此定方案，再派发实现和审查：

```text
/paseo-routed 解释一下这个仓库的配置加载是怎么工作的，测试在哪里
/paseo-routed 导出 CSV 时中文列名乱码，查出原因并修掉，补一个回归测试
```

在对话里已经把方案谈定，或者手上有一张票据，就用 `/implement-routed`。它会先写测试，再实现、审查、提交：

```text
/implement-routed 按刚才定的方案给 sync 命令加 --dry-run：只列出要改的文件，不写盘
/implement-routed #123
```

需求还模糊，可以先让 `grilling` 追问几轮，问清楚了再交给 `/implement-routed`。只想在这一次换个模型，就加参数：

```text
/implement-routed --roster alt #123
/native-implement-routed-cc --reviewer fable #123
```

### 大需求

大需求通常按下面的顺序走，每一步都在同一个仓库里执行：

1. `/grill-with-docs <想法>`：逐条追问方案，术语写进 glossary，关键决策记成 ADR。不需要留文档时用 `grilling`。
2. `/to-spec`：把讨论结果整理成 spec，发到项目的 issue tracker。
3. `/to-tickets`：把 spec 拆成票据，每张写明被哪些票据阻塞。拆分方案你确认后才发布。
4. `/implement-spec-routed <spec 和票据位置>`：没有阻塞的票据各开一个 worktree 并行实现，合进一条集成分支，最后统一审查。
5. 同时跑着几个这样的运行时，另开一个会话执行 `/paseo-watch start`，它只汇报变化，你的决定由它转达回去。
6. 做完后执行 `/retro`，把这次暴露的问题落实成检查脚本、导航指引或审查规则。

以给 CLI 加插件机制为例，tracker 用本地文件：

```text
/grill-with-docs 给 CLI 加插件机制：第三方包注册子命令，主程序启动时按需加载
（回答几轮追问，定下加载时机、版本兼容和出错时的行为）
/to-spec
（spec 写到 .scratch/plugin-system/spec.md）
/to-tickets .scratch/plugin-system/spec.md
（确认拆分后，票据写到 .scratch/plugin-system/issues/01-*.md 等文件）
/implement-spec-routed .scratch/plugin-system/spec.md，票据在 .scratch/plugin-system/issues/
/retro
```

tracker 用 GitHub 时，第 3、4 步传 issue 号，比如 `/to-tickets #45`、`/implement-spec-routed #45`。

运行中断了，回到原会话说"继续"即可。主会话会先检查还在跑的代理和各个 worktree 的 git 状态，再接着做。

### 搭配技能

上面用到的 `grilling`、`grill-with-docs`、`to-spec`、`to-tickets`、`retro` 来自 [mattpocock/skills](https://github.com/mattpocock/skills)。它们是可选的，没装也不影响 routed 技能运行。

| 技能 | 用法 |
| --- | --- |
| `grilling` | 动手前逐条追问方案，把需求问清楚 |
| `grill-with-docs` | 同样逐条追问，边问边把术语写进 glossary、把决策记成 ADR |
| `to-spec` | 把讨论结果整理成 spec，发到项目的 issue tracker |
| `to-tickets` | 把 spec 拆成带阻塞关系的票据，交给 `implement-spec-routed` 或 `native-implement-spec-routed-*` 执行 |
| `retro` | 跑完一次复盘，改进 `CLAUDE.md`/`AGENTS.md`、检查脚本和技能 |

命令里另外三个是依赖：`grill-with-docs` 会加载 `grilling` 和 `domain-modeling`，`to-spec` 和 `to-tickets` 要先用 `setup-matt-pocock-skills` 配置 issue tracker 和标签，`retro` 会加载 `writing-for-agents`。

```bash
npx skills add mattpocock/skills -g -a claude-code -a codex \
  --skill grilling --skill grill-with-docs --skill to-spec --skill to-tickets \
  --skill retro --skill domain-modeling --skill setup-matt-pocock-skills \
  --skill writing-for-agents
```

装好后，在每个要用的仓库里先运行一次 `/setup-matt-pocock-skills`，选 tracker（GitHub、GitLab 或本地 `.scratch/` 文件）。除 `grilling` 和 `domain-modeling` 外，这几个技能都只能手动调用。

## 许可

[MIT](LICENSE)

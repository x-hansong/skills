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

### 依赖

- [Paseo](https://paseo.sh) CLI，daemon 要在运行：`npm install -g @getpaseo/cli`
- Paseo 自带的编排技能：`npx skills add getpaseo/paseo`
- 两个 implement 技能还需要 [mattpocock/skills](https://github.com/mattpocock/skills) 里的 `implement`、`implement-spec`、`tdd`、`code-review`

`setup-paseo-routed` 会逐项检查，并告诉你缺了什么。

### 安装

```bash
npx skills add x-hansong/skills -g -a claude-code -a codex \
  --skill setup-paseo-routed --skill paseo-routed-guide \
  --skill paseo-routed --skill implement-routed --skill implement-spec-routed
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

## 许可

[MIT](LICENSE)

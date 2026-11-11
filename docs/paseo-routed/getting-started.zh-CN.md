# Paseo Routed 上手指南

## 1. 安装

先装好 Paseo 并启动 daemon（见 [paseo.sh](https://paseo.sh/docs)），再装技能：

```bash
npx skills add x-hansong/skills -g -a claude-code -a codex \
  --skill setup-paseo-routed --skill paseo-routed-guide \
  --skill paseo-routed --skill implement-routed --skill implement-spec-routed \
  --skill paseo-watch
```

## 2. 运行 setup

```text
/setup-paseo-routed
```

它会只读检查十项，并列成一张表：

| 检查项 | 看什么 |
| --- | --- |
| Paseo CLI、daemon | 是否安装、是否在运行、CLI 和 daemon 版本是否一致 |
| MCP、MCP 注入 | Paseo 启动的代理能不能用 Paseo 工具 |
| Provider、profile | 有没有能担任 `worker` 和 `reviewer` 的 profile |
| Roster 配置、roster 里的 profile | `~/.paseo-routed/config.yaml` 是否合法，里面写的 profile 是否都存在 |
| 笔记目录 | 是否存在、能否写入 |
| 技能 | Paseo 自带技能和这套技能本身，按你用的每个代理分别检查 |

接着，它会针对没打 ✅ 的项给出方案。已有的 profile 合适就直接用；需要新建时，它会列出你的 provider 实际能用的模型让你挑。你确认之前它什么都不写。写入前会先备份 Paseo 配置，profile 通过脚本写入，脚本会核对其它 profile 一个不少。

随时可以重跑；配置齐全时它只会报告全部 ✅。`/setup-paseo-routed check` 只出报告，不提修改。

## 3. 第一次运行

```text
/paseo-routed 解释一下这个仓库的配置加载是怎么工作的，测试在哪里
```

过程大致是：

1. 主会话解析 roster，记到 `~/.paseo-routed/notes/<主题>/`。
2. 写下范围和完成条件，派 worker 做只读探索。
3. worker 汇报后，主会话核对证据，再回答你。

要改代码时，先在对话里定好方案，然后：

```text
/implement-routed 按上面的方案实现
```

worker 先写测试再实现，逐步提交；reviewer 只读审查 diff。P0–P2 的问题交给一个新的 worker 修，P3 交给你决定。

## 4. 切换 roster

在 `~/.paseo-routed/config.yaml` 里加一套用其它 profile 的 roster，然后：

```text
/paseo-routed --roster alt <任务>
```

想对比的 roster 设 `compare: true`，每次运行会把用到的 profile、返工轮数和审查发现数记到共享笔记里。

## 排查

| 现象 | 处理 |
| --- | --- |
| 提示“run /setup-paseo-routed” | roster 配置不存在或格式不对 |
| 提示找不到 roster 或 profile | 名字必须完全一致；`/setup-paseo-routed check` 会列出对不上的地方 |
| 派出去的代理调不了 Paseo 工具 | MCP 注入没开，setup 会帮你打开 |
| 跑到一半停了 | 说“继续”，主会话会先检查运行中的代理和各个 worktree |

# skills

Agent skills by [x-hansong](https://github.com/x-hansong), for Claude Code and Codex. Install with the [skills CLI](https://skills.sh/docs).

[中文](README.zh-CN.md)

## Paseo Routed

Keep design and orchestration in your session, and let [Paseo](https://paseo.sh) agents do the work: a **worker** explores, researches, implements and merges; a separate **reviewer** reviews and diagnoses. Which Paseo profiles play those roles comes from a **roster** you can switch per run, so trying another model or harness is a config change, not a new skill.

| Skill | Invoke | Use it for |
| --- | --- | --- |
| [`setup-paseo-routed`](skills/paseo-routed/setup-paseo-routed/SKILL.md) | you | First-time setup and health checks: detects what you have, proposes only the missing pieces, writes after you confirm |
| [`paseo-routed-guide`](skills/paseo-routed/paseo-routed-guide/SKILL.md) | you or the agent | Which skill to use, how rosters work, a guided first run |
| [`paseo-routed`](skills/paseo-routed/paseo-routed/SKILL.md) | you or the agent | Any task: this session designs, the worker explores and implements, the reviewer reviews |
| [`implement-routed`](skills/paseo-routed/implement-routed/SKILL.md) | you | An agreed plan, spec or single ticket, following `implement` |
| [`implement-spec-routed`](skills/paseo-routed/implement-spec-routed/SKILL.md) | you | A spec with a dependency graph of tickets, following `implement-spec` |
| [`paseo-watch`](skills/paseo-routed/paseo-watch/SKILL.md) | you | Many orchestrators running: a heartbeat reports what changed, rebuilds the background of each pending decision, and relays your answers |

### Requirements

- [Paseo](https://paseo.sh) CLI with a running daemon: `npm install -g @getpaseo/cli`
- Paseo's orchestration skills: `npx skills add getpaseo/paseo`
- For the implement skills, from [mattpocock/skills](https://github.com/mattpocock/skills): `implement`, `implement-spec`, `tdd`, `code-review`

`setup-paseo-routed` checks all of these and tells you what's missing.

### Install

```bash
npx skills add x-hansong/skills -g -a claude-code -a codex \
  --skill setup-paseo-routed --skill paseo-routed-guide \
  --skill paseo-routed --skill implement-routed --skill implement-spec-routed \
  --skill paseo-watch
```

Then, in Claude Code or Codex:

```text
/setup-paseo-routed
```

### Rosters

`~/.paseo-routed/config.yaml`:

```yaml
version: 1
default_roster: main
rosters:
  main: { worker: Builder, reviewer: Critic }
  alt:  { worker: Builder-alt, reviewer: Critic-alt, compare: true }
notes_dir: ~/.paseo-routed/notes
```

`/paseo-routed --roster alt <task>` uses `alt` for one run; change `default_roster` to switch for good. `compare: true` logs rework rounds and review findings so you can compare rosters.

More in the [getting started guide](docs/paseo-routed/getting-started.md).

## Native Routed

The same division of labour without Paseo, built on each host's own subagents. One set for Claude Code (`-cc`) and one for Codex (`-codex`); each runs only in its own host and never calls the other. A **worker** subagent explores, implements and merges; a **reviewer** subagent on a stronger model reviews; on a repeated failure a two-member **committee** diagnoses. Subagents end with your session, so runs resume from notes and git.

| Skill (`-cc` / `-codex`) | Invoke | Use it for |
| --- | --- | --- |
| [`native-routed-setup-*`](skills/native-routed/native-routed-setup-cc/SKILL.md) | you | Pick the models for worker, reviewer and committee; health checks. Required once for Codex |
| [`native-routed-guide-*`](skills/native-routed/native-routed-guide-cc/SKILL.md) | you or the agent | Which skill to use, how models are chosen, a guided first run |
| [`native-routed-*`](skills/native-routed/native-routed-cc/SKILL.md) | you or the agent | Any task: this session designs, the worker explores and implements, the reviewer reviews |
| [`native-implement-routed-*`](skills/native-routed/native-implement-routed-cc/SKILL.md) | you | An agreed plan, spec or single ticket, following `implement` |
| [`native-implement-spec-routed-*`](skills/native-routed/native-implement-spec-routed-cc/SKILL.md) | you | A spec with a dependency graph of tickets, following `implement-spec` |
| [`native-watch-*`](skills/native-routed/native-watch-cc/SKILL.md) | you | Many routed sessions running: reports what changed, rebuilds the background of each pending decision, relays your answers |

How the two hosts differ:

| | Claude Code | Codex |
| --- | --- | --- |
| Subagents | Agent tool; `isolation: "worktree"` for parallel units | `spawn_agent` with `fork_turns: "none"`; the orchestrator creates worktrees |
| Models | Defaults: reviewer `opus`, committee `opus` + `fable`; config optional | No defaults; run setup once to choose from the models `spawn_agent` offers |
| Watch cadence | `CronCreate` in the watching session | Heartbeat automation in the Codex app; on demand (`now`) in the CLI |
| Watch relay | `SendMessage` | `codex queue` |

### Requirements

- Claude Code, or Codex with the `multi_agent` feature on
- From [mattpocock/skills](https://github.com/mattpocock/skills): `code-review`, and for the implement skills `implement`, `implement-spec`, `tdd`

### Install

Install each set only for its own host:

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

Then run `/native-routed-setup-cc` in Claude Code, or `$native-routed-setup-codex` in Codex.

### Models

`~/.native-routed/config.yaml`, one section per host; each setup skill edits only its own:

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

`--reviewer <model>` (Codex: `<model>/<effort>`) overrides it for one run.

## License

[MIT](LICENSE)

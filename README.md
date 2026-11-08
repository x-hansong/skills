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

## License

[MIT](LICENSE)

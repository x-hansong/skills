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
| [`implement-routed`](skills/paseo-routed/implement-routed/SKILL.md) | you | An agreed plan, spec or single ticket, tests first, then review and commits |
| [`implement-spec-routed`](skills/paseo-routed/implement-spec-routed/SKILL.md) | you | A spec with a dependency graph of tickets: the ready frontier in parallel worktrees, one integration branch, one review at the end |
| [`paseo-watch`](skills/paseo-routed/paseo-watch/SKILL.md) | you | Many orchestrators running: a heartbeat reports what changed, flags stalled orchestrators, stopped background jobs it was asked to probe, and decisions about to lose their prompt cache, rebuilds the background of each pending decision, and relays your answers |

### Requirements

- [Paseo](https://paseo.sh) CLI with a running daemon: `npm install -g @getpaseo/cli`
- Paseo's orchestration skills: `npx skills add getpaseo/paseo`

`setup-paseo-routed` checks all of these and tells you what's missing.

Install a skill together with the skills it loads:

| Skill | Also install |
| --- | --- |
| `paseo-routed` | `paseo`, `paseo-advisor`, `paseo-committee` (from Paseo) |
| `implement-routed` | `paseo-routed` and what it needs |
| `implement-spec-routed` | `paseo-routed` and what it needs |
| `paseo-routed-guide` | `setup-paseo-routed`, `paseo-routed` |
| `setup-paseo-routed`, `paseo-watch` | nothing |

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
| [`native-implement-routed-*`](skills/native-routed/native-implement-routed-cc/SKILL.md) | you | An agreed plan, spec or single ticket, tests first, then review and commits |
| [`native-implement-spec-routed-*`](skills/native-routed/native-implement-spec-routed-cc/SKILL.md) | you | A spec with a dependency graph of tickets: the ready frontier in parallel worktrees, one integration branch, one review at the end |
| [`native-watch-*`](skills/native-routed/native-watch-cc/SKILL.md) | you | Many routed sessions running: reports what changed, flags stalled sessions, stopped background jobs it was asked to probe, and decisions about to lose their prompt cache, rebuilds the background of each pending decision, relays your answers |

How the two hosts differ:

| | Claude Code | Codex |
| --- | --- | --- |
| Subagents | Agent tool; `isolation: "worktree"` for parallel units | `spawn_agent` with `fork_turns: "none"`; the orchestrator creates worktrees |
| Models | Defaults: reviewer `opus`, committee `opus` + `fable`; config optional | No defaults; run setup once to choose from the models `spawn_agent` offers |
| Watch cadence | `CronCreate` in the watching session | Heartbeat automation in the Codex app; on demand (`now`) in the CLI |
| Watch relay | `SendMessage` | `codex queue` |

### Requirements

- Claude Code, or Codex with the `multi_agent` feature on

Install a skill together with the skills it loads, all from the same host's set:

| Skill (`-cc` / `-codex`) | Also install |
| --- | --- |
| `native-implement-routed-*`, `native-implement-spec-routed-*` | `native-routed-*` |
| `native-routed-guide-*` | `native-routed-setup-*`, `native-routed-*` |
| `native-routed-*` | nothing; Codex needs a config from `native-routed-setup-codex` first |
| `native-watch-*` | nothing; it watches runs started by `native-routed-*` and the implement skills |
| `native-routed-setup-*` | nothing |

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
  budget: medium            # optional: small | medium | large | unlimited
  reviewer: opus
  committee: [opus, fable]
codex:
  reviewer: { model: <strong-model>, effort: high }
  committee:
    - { model: <strong-model>, effort: high }
    - { model: <other-strong-model>, effort: high }
```

`budget` sets the reasoning effort of every role without its own; `committee` runs one member per entry. `--reviewer <model>[/<effort>]` and `--budget <budget>` override the config for one run. A model that fails to start mid-run falls back in a fixed order, and the report says so.

## Usage

The examples use the Paseo command names. For the native sets, swap in the matching name; in Codex, start with `$` instead of `/`:

| To | Paseo | Claude Code native | Codex native |
| --- | --- | --- | --- |
| Run any task | `/paseo-routed` | `/native-routed-cc` | `$native-routed-codex` |
| Implement a settled plan | `/implement-routed` | `/native-implement-routed-cc` | `$native-implement-routed-codex` |
| Implement a spec and its tickets in parallel | `/implement-spec-routed` | `/native-implement-spec-routed-cc` | `$native-implement-spec-routed-codex` |
| Watch several runs | `/paseo-watch` | `/native-watch-cc` | `$native-watch-codex` |

Size the work first. If it fits one branch and a commit or two, and its acceptance fits in a sentence or two, it is small. If it splits into several tickets that depend on each other, spans several modules, or needs shared terms and recorded design decisions first, treat it as large.

### Small work

With no plan yet, use `/paseo-routed`. This session has a worker explore the code, settles the plan from what it finds, then dispatches implementation and review:

```text
/paseo-routed Explain how config loading works in this repo and where its tests are
/paseo-routed Non-ASCII column names come out garbled in CSV export; find the cause, fix it, add a regression test
```

With a plan already agreed in the conversation, or a single ticket, use `/implement-routed`. It writes tests first, then implements, reviews and commits:

```text
/implement-routed Add --dry-run to the sync command as we just agreed: list the files it would change, write nothing
/implement-routed #123
```

When the requirement is still fuzzy, let `grilling` question you first, then hand the result to `/implement-routed`. To use other models for one run only, pass a flag:

```text
/implement-routed --roster alt #123
/native-implement-routed-cc --reviewer fable #123
```

### Large work

Large work usually goes like this, every step in the same repo:

1. `/grill-with-docs <idea>`: an interview that settles the plan question by question, writing terms to the glossary and key decisions to ADRs. Use `grilling` when you don't need the docs.
2. `/to-spec`: turn the discussion into a spec on the project's issue tracker.
3. `/to-tickets`: split the spec into tickets, each naming the tickets that block it. Nothing is published until you approve the split.
4. `/implement-spec-routed <spec and ticket location>`: unblocked tickets are implemented in parallel, each in its own worktree, merged into one integration branch and reviewed together at the end.
5. With several such runs going, run `/paseo-watch start` in another session. It reports only what changed and relays your decisions back.
6. When it is done, run `/retro` to turn what went wrong into checks, navigation pointers or review rules.

For example, adding a plugin system to a CLI, with a local-file tracker:

```text
/grill-with-docs Add plugins to the CLI: third-party packages register subcommands, loaded on demand at startup
(answer a few rounds of questions: when plugins load, version compatibility, what happens on errors)
/to-spec
(the spec goes to .scratch/plugin-system/spec.md)
/to-tickets .scratch/plugin-system/spec.md
(after you approve the split, tickets go to .scratch/plugin-system/issues/01-*.md and so on)
/implement-spec-routed .scratch/plugin-system/spec.md, tickets in .scratch/plugin-system/issues/
/retro
```

With a GitHub tracker, pass the issue number in steps 3 and 4, for example `/to-tickets #45` and `/implement-spec-routed #45`.

If a run stops, say "continue" in the same session. This session checks the agents still running and each worktree's git state before going on.

### Companion skills

`grilling`, `grill-with-docs`, `to-spec`, `to-tickets` and `retro` above come from [mattpocock/skills](https://github.com/mattpocock/skills). They are optional; the routed skills run without them.

| Skill | Use |
| --- | --- |
| `grilling` | Stress-test the plan question by question before any work starts |
| `grill-with-docs` | The same interview, writing terms to the glossary and decisions to ADRs as it goes |
| `to-spec` | Turn the discussion into a spec on the project's issue tracker |
| `to-tickets` | Split a spec into tickets with blocking edges, ready for `implement-spec-routed` or `native-implement-spec-routed-*` |
| `retro` | Review a finished run and improve `CLAUDE.md`/`AGENTS.md`, checks and skills |

The command also installs three dependencies: `grill-with-docs` loads `grilling` and `domain-modeling`, `to-spec` and `to-tickets` need `setup-matt-pocock-skills` to configure the issue tracker and labels, and `retro` loads `writing-for-agents`.

```bash
npx skills add mattpocock/skills -g -a claude-code -a codex \
  --skill grilling --skill grill-with-docs --skill to-spec --skill to-tickets \
  --skill retro --skill domain-modeling --skill setup-matt-pocock-skills \
  --skill writing-for-agents
```

Then run `/setup-matt-pocock-skills` once in each repo where you use them and pick a tracker (GitHub, GitLab or local `.scratch/` files). Apart from `grilling` and `domain-modeling`, these skills are manual-only.

## License

[MIT](LICENSE)

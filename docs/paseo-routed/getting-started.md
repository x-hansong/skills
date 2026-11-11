# Getting started with Paseo Routed

## 1. Install

Install Paseo and start its daemon (see [paseo.sh](https://paseo.sh/docs)), then the skills:

```bash
npx skills add x-hansong/skills -g -a claude-code -a codex \
  --skill setup-paseo-routed --skill paseo-routed-guide \
  --skill paseo-routed --skill implement-routed --skill implement-spec-routed \
  --skill paseo-watch
```

## 2. Run setup

```text
/setup-paseo-routed
```

It checks ten things read-only and shows a table:

| Check | What it looks at |
| --- | --- |
| Paseo CLI, daemon | Installed, running, CLI and daemon versions match |
| MCP, MCP injection | Agents started by Paseo can use Paseo tools |
| Providers, profiles | Something can play `worker` and `reviewer` |
| Roster config, roster profiles | `~/.paseo-routed/config.yaml` is valid and every profile it names exists |
| Notes directory | Exists and is writable |
| Skills | Paseo's skills and this set, for each agent you use |

Then it proposes a plan for whatever isn't ✅. It reuses profiles you already have where they fit; when it has to create one, it lists the models your providers actually offer and lets you pick. Nothing is written until you confirm. Paseo's config is backed up first, and profiles are written through a script that checks every other profile survived.

Run it again any time; when everything is in place it just reports ✅. `/setup-paseo-routed check` reports without offering to change anything.

## 3. First run

```text
/paseo-routed explain how the config loader in this repo works and where it's tested
```

What you'll see:

1. The session resolves the roster and records it in `~/.paseo-routed/notes/<topic>/`.
2. It writes a scope and a done-condition, and dispatches the worker for read-only exploration.
3. When the worker reports, the session checks its evidence and answers you.

For a change, agree on a plan in conversation, then:

```text
/implement-routed the plan above
```

The worker implements test-first and commits; the reviewer reviews the diff read-only; findings P0–P2 go to a fresh worker, P3 come to you.

## 4. Switch rosters

Add a roster with other profiles to `~/.paseo-routed/config.yaml`, then:

```text
/paseo-routed --roster alt <task>
```

Set `compare: true` on rosters you want to compare. Each run then logs its profiles, rework rounds and review findings to the shared notes.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| "run /setup-paseo-routed" | The roster config is missing or invalid |
| A roster or profile "not found" | Names must match exactly; `/setup-paseo-routed check` lists the mismatch |
| Dispatched agents can't call Paseo tools | MCP injection is off; setup turns it on |
| A run stopped halfway | Say "continue"; the session checks running agents and worktrees first |

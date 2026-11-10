# Scenarios

## Which skill

| You have | Use | What happens |
| --- | --- | --- |
| A task, question or rough idea; no plan yet | `$native-routed-codex <task>` | This session designs the plan from the worker's exploration, then dispatches implementation and review |
| An agreed plan, a spec file, or one ticket | `$native-implement-routed-codex <plan or ticket>` | Tests first, review, commits, with the worker implementing and the reviewer reviewing |
| A spec split into tickets with blocking edges | `$native-implement-spec-routed-codex <spec>` | Works the ready frontier in parallel worktrees, merges onto one integration branch, reviews once at the end |
| Several routed sessions running and you lose track of them | `$native-watch-codex start` | A heartbeat automation (Codex app) or on-demand `now` patrols the registered runs, reports only changes, rebuilds the background of each pending decision, and relays your answers. `$native-watch-codex stop` ends it |
| Want other models, or something stopped working | `$native-routed-setup-codex` | Detects, suggests models, writes after you confirm, re-checks. `$native-routed-setup-codex check` only reports |

A typical path for a feature: grill or discuss the idea → `to-spec` → `to-tickets` → `$native-implement-spec-routed-codex`. For a single change: agree on the plan in conversation → `$native-implement-routed-codex`.

## Roles

- **This session** designs and orchestrates. It never explores, researches or implements the task itself, and never hands the design to another agent.
- **worker** explores, researches, implements, merges and fixes review findings.
- **reviewer** reviews read-only and diagnoses hard failures. It never reviews work it wrote.
- **committee**: two read-only subagents called when the same failure happens twice; one digs for the root cause, the other challenges the approach.

All of them are subagents started with Codex's `spawn_agent`, without this conversation's history.

## Models

| Role | Default | Change it |
| --- | --- | --- |
| worker | this session's model | `codex.worker` in the config, or `--worker <model>[/<effort>]` |
| reviewer | none: set by setup | `codex.reviewer`, or `--reviewer <model>[/<effort>]` |
| committee | none: set by setup | `codex.committee` |

The config is `~/.native-routed/config.yaml`, written by `$native-routed-setup-codex`. Model names differ between machines and accounts, so the skills ship none: setup reads the models `spawn_agent` offers and suggests a strong one for the reviewer and two for the committee. Without that config the routed skills stop and point to setup.

## Common questions

**How is this different from paseo-routed?** No Paseo daemon, profiles or rosters: roles are Codex subagents, and models come from one small config. In exchange, subagents end with this session and can't use another harness for review.

**Where do notes go?** `~/.native-routed/notes/<topic>/`, outside the repo, so every subagent can read them and they never get committed. `session.json` there lets `native-watch-codex` find the run.

**Can the reviewer write files?** The tool allows it. Review briefs state read-only, and the orchestrator checks `git status` after every review.

**A run stopped halfway.** Say "continue". Subagents don't survive a restart, so the orchestrator reads the notes and checks each worktree's `git log` and `git status`, then re-dispatches what's unfinished.

**The same failure keeps happening.** On its second occurrence the orchestrator calls the committee for an independent root-cause analysis instead of retrying.

**The watch doesn't patrol on its own.** Scheduled patrols need the `automation_update` tool, which the Codex app has and the CLI doesn't. In the CLI, run `$native-watch-codex now` when you want a report.

**A relayed decision didn't run.** Relays use `codex queue` without `--resume`, so the message waits until you open that session. Ask the watch to resume it if you want it to run unattended.

# Scenarios

## Which skill

| You have | Use | What happens |
| --- | --- | --- |
| A task, question or rough idea; no plan yet | `/native-routed-cc <task>` | This session designs the plan from the worker's exploration, then dispatches implementation and review |
| An agreed plan, a spec file, or one ticket | `/native-implement-routed-cc <plan or ticket>` | Tests first, review, commits, with the worker implementing and the reviewer reviewing |
| A spec split into tickets with blocking edges | `/native-implement-spec-routed-cc <spec>` | Works the ready frontier in parallel worktrees, merges onto one integration branch, reviews once at the end |
| Several routed sessions running and you lose track of them | `/native-watch-cc start` | A cron job in this session patrols the registered runs, reports only changes, rebuilds the background of each pending decision, and relays your answers. `/native-watch-cc stop` ends it |
| Want other models, or something stopped working | `/native-routed-setup-cc` | Detects, suggests models, writes after you confirm, re-checks. `/native-routed-setup-cc check` only reports |

A typical path for a feature: grill or discuss the idea → `to-spec` → `to-tickets` → `/native-implement-spec-routed-cc`. For a single change: agree on the plan in conversation → `/native-implement-routed-cc`.

## Roles

- **This session** designs and orchestrates. It never explores, researches or implements the task itself, and never hands the design to another agent.
- **worker** explores, researches, implements, merges and fixes review findings.
- **reviewer** reviews read-only and diagnoses hard failures. It never reviews work it wrote.
- **committee**: two read-only subagents called when the same failure happens twice; one digs for the root cause, the other challenges the approach.

All of them are subagents started with Claude Code's Agent tool.

## Models

| Role | Default | Change it |
| --- | --- | --- |
| worker | the host's subagent default (`CLAUDE_CODE_SUBAGENT_MODEL` when set) | `cc.worker` in the config, or `--worker <model>` |
| reviewer | `opus` | `cc.reviewer`, or `--reviewer <model>` |
| committee | `opus` and `fable` | `cc.committee` |

The config is `~/.native-routed/config.yaml`, written by `/native-routed-setup-cc`. Values are whatever the Agent tool accepts for `model`. An explicit `model` overrides `CLAUDE_CODE_SUBAGENT_MODEL`, which is how the reviewer ends up on a stronger model than the worker.

## Common questions

**How is this different from paseo-routed?** No Paseo daemon, profiles or rosters: roles are Claude Code subagents, and models come from one small config. In exchange, subagents end with this session and can't use another harness for review.

**Where do notes go?** `~/.native-routed/notes/<topic>/`, outside the repo, so every subagent can read them and they never get committed. `session.json` there lets `native-watch-cc` find the run.

**Can the reviewer write files?** The tool allows it. Review briefs state read-only, and the orchestrator checks `git status` after every review.

**A run stopped halfway.** Say "continue". Subagents don't survive a restart, so the orchestrator reads the notes and checks each worktree's `git log` and `git status`, then re-dispatches what's unfinished.

**The same failure keeps happening.** On its second occurrence the orchestrator calls the committee for an independent root-cause analysis instead of retrying.

**The watch stopped reporting.** Its cron job lives only in the watching session, fires only while that session is idle, and expires after 7 days. Run `/native-watch-cc start` again.

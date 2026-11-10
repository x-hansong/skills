# Scenarios

## Which skill

| You have | Use | What happens |
| --- | --- | --- |
| A task, question or rough idea; no plan yet | `/paseo-routed <task>` | This session designs the plan from the worker's exploration, then dispatches implementation and review |
| An agreed plan, a spec file, or one ticket | `/implement-routed <plan or ticket>` | Tests first, review, commits, with the worker implementing and the reviewer reviewing |
| A spec split into tickets with blocking edges | `/implement-spec-routed <spec>` | Works the ready frontier in parallel worktrees, merges onto one integration branch, reviews once at the end |
| Several orchestrators running and you lose track of them | `/paseo-watch start` | A Paseo heartbeat patrols top-level orchestrators, reports only changes, rebuilds the background of each pending decision, and relays your answers. `/paseo-watch stop` ends it |
| Nothing set up yet, or something stopped working | `/setup-paseo-routed` | Detects, plans, writes after you confirm, re-checks. `/setup-paseo-routed check` only reports |

A typical path for a feature: grill or discuss the idea → `to-spec` → `to-tickets` → `/implement-spec-routed`. For a single change: agree on the plan in conversation → `/implement-routed`.

## Roles

- **This session** designs and orchestrates. It never explores, researches or implements the task itself, and never hands the design to another agent.
- **worker** explores, researches, implements, merges and fixes review findings.
- **reviewer** reviews read-only and diagnoses hard failures. It never reviews work it wrote.

## Rosters

A roster says which Paseo profile plays each role. They live in `~/.paseo-routed/config.yaml`:

```yaml
default_roster: main
rosters:
  main: { worker: Builder, reviewer: Critic }
  alt:  { worker: Builder-alt, reviewer: Critic-alt, compare: true }
```

- One run on another roster: `/paseo-routed --roster alt <task>`, or say "use the alt roster".
- Every run: change `default_roster`.
- Try a new model: create a Paseo profile for it, add a roster line. No skill changes.
- Compare rosters: set `compare: true`. Each run logs rework rounds and review findings to the shared notes.
- A personal shortcut such as `/paseo-routed-alt`: create a local skill whose body is "Run the paseo-routed skill with --roster alt and these arguments: $ARGUMENTS". Keep it out of shared repos.

## Common questions

**Why not the host's built-in subagents?** Paseo agents run on the profile you chose, in their own worktrees, survive this session, and can use a different model or harness for review. The skills never fall back to built-in subagents; they stop and tell you.

**Where do notes go?** `<notes_dir>/<topic>/`, outside the repo, so every agent can read them and they never get committed.

**The reviewer profile allows writes. Is that a problem?** Review briefs state read-only, and the orchestrator checks `git status` after every review.

**A run stopped halfway.** Say "continue". The orchestrator lists running agents and checks each worktree's `git log` and `git status` before doing anything else.

**The same failure keeps happening.** On its second occurrence the orchestrator calls `paseo-committee` for an independent root-cause analysis instead of retrying.

**A profile or roster is missing.** The run stops and names it. Run `/setup-paseo-routed`.

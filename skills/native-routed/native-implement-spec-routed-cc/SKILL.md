---
name: native-implement-spec-routed-cc
description: "Implement a spec and its dependency graph of tickets in Claude Code without Paseo: this session orchestrates the ready frontier, worker subagents implement and merge each ticket, a reviewer subagent on a stronger model reviews and diagnoses. Follows the current project's integration, testing and delivery rules."
argument-hint: "[--worker <model>] [--reviewer <model>] <spec path or ticket source>"
disable-model-invocation: true
license: MIT
compatibility: "Claude Code only. Requires everything native-routed-cc requires, plus the implement-spec, tdd and code-review skills (npx skills add mattpocock/skills --skill implement-spec --skill tdd --skill code-review)."
metadata:
  author: x-hansong
---

# Native routed spec implementation (Claude Code)

**Spec:** $ARGUMENTS

Load the `implement-spec` skill and keep its ticket dependency graph, ready frontier, per-ticket worktrees, integration branch and delivery requirements. Then load the `native-routed-cc` skill and apply its model resolution, dispatch, recovery and acceptance rules to this run. The overrides below win over `implement-spec`. Pass `--worker` and `--reviewer` through to model resolution.

The input is a spec, its tickets and how they are tracked. Without a ticket graph, when the user just wants a task or plan carried out, use `native-implement-routed-cc`. When tickets really must be closed, first settle where they live and how they are closed.

## Role overrides

| `implement-spec` role or step | Here |
| --- | --- |
| Orchestrator | This session schedules the frontier and checks real diffs, test evidence and each ticket's acceptance checks |
| Exploration subagent | Read-only worker on demand; notes go to the notes directory outside the repo |
| Implementer subagent | A fresh worker per ticket, started with `isolation: "worktree"` |
| Merger subagent | Another worker, merging and verifying per the project's integration rules |
| `code-review` step | A fresh reviewer subagent on the reviewer model, read-only, over the integration branch; pass the full baseline SHA, the spec and the ticket source |
| Review fixes | A fresh worker; implementer and reviewer are always different agents |
| Same failure a second time | The committee from `native-routed-cc`, for an independent diagnosis and plan |

## Tickets, baseline and parallelism

1. Read the project's `AGENTS.md` (or `CLAUDE.md`) and its ticket, testing, integration and handoff conventions. Check existing changes and record the full baseline SHA. Verify the baseline with the project's own checks and note pre-existing failures and their impact. Write the scope and `session.json` to `~/.native-routed/notes/<topic>/` as `native-routed-cc` describes.
2. Create the integration branch. Dispatch each ready ticket to a fresh worker with: ticket id, goal, acceptance checks, full baseline SHA, notes path and the project rules' paths. Record each worktree in `session.json`.
3. When resuming a worktree, check its actual baseline and uncommitted changes. Adjust branches per project convention; keep existing changes and never overwrite state with an unconditional reset.
4. Each implementer uses the `tdd` skill, commits and logs progress per project convention, runs the relevant and new tests, and reports actual changes and deviations.
5. The merger merges in a separate candidate tree and runs the project's required build, tests and receipt checks. Only after they pass does it update the integration branch and the frontier.
6. When every ticket is done, run the independent review, fix and re-check, then close out with `implement-spec`'s delivery steps and the project's tracking.

On every continue or resume, read the notes, then check each worktree's `git log` and `git status` first. Subagents from an earlier session are gone; re-dispatch unfinished tickets to fresh workers.

## Acceptance

Check each ticket's commits, acceptance checks, diff and test log exit code. Use the project's receipt mechanism when it has one; otherwise keep reproducible test commands, logs and exit codes.

Handle draft PRs, ticket closing, branch merges, pushes and worktree cleanup per the project's rules, within the user's existing authorization. Report actual results, deviations and anything unverified.

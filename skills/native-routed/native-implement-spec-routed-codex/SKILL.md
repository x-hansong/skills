---
name: native-implement-spec-routed-codex
description: "Implement a spec and its dependency graph of tickets in Codex without Paseo: this session orchestrates the ready frontier, worker subagents implement and merge each ticket, a reviewer subagent on a stronger model reviews and diagnoses. Follows the current project's integration, testing and delivery rules."
argument-hint: "[--worker <model>[/<effort>]] [--reviewer <model>[/<effort>]] <spec path or ticket source>"
disable-model-invocation: true
license: MIT
compatibility: "Codex only. Requires everything native-routed-codex requires."
metadata:
  author: x-hansong
---

# Native routed spec implementation (Codex)

**Spec:** $ARGUMENTS

Load the `native-routed-codex` skill and apply its model resolution, dispatch, recovery and acceptance rules, test discipline and review method to this run. Pass `--worker` and `--reviewer` through to model resolution. Reply in the user's language.

The input is a spec, its tickets and how they are tracked. Without a ticket graph, when the user just wants a task or plan carried out, use `native-implement-routed-codex`. When tickets really must be closed, first settle where they live and how they are closed.

## Roles

| Step | Who |
| --- | --- |
| Orchestrator | This session schedules the frontier and checks real diffs, test evidence and each ticket's acceptance checks |
| Exploration | Read-only worker on demand; notes go to the notes directory outside the repo |
| Implementation | A fresh worker per ticket, in a worktree this session creates as `native-routed-codex` describes |
| Merge | Another worker, merging and verifying per the project's integration rules |
| Final review | A fresh reviewer subagent on the reviewer model, read-only, over the integration branch; pass the full baseline SHA, the spec and the ticket source |
| Review fixes | A fresh worker; implementer and reviewer are always different agents |
| Same failure a second time | The committee from `native-routed-codex`, for an independent diagnosis and plan |

## Task graph

The tickets are not a list of steps but a task graph with blocking edges, so there is always a frontier of tickets ready to start. Start every ticket's worker as soon as it is on the frontier, in the background where the host allows, and start the next ones whenever a merge moves the frontier.

Every agent starts with a fresh context. Keep messages to and from agents short: pass pointers to the spec, the tickets, the notes and earlier commits instead of restating them.

## Tickets, baseline and parallelism

1. Read the project's `AGENTS.md` (or `CLAUDE.md`) and its ticket, testing, integration and handoff conventions. Check existing changes and record the full baseline SHA. Verify the baseline with the project's own checks and note pre-existing failures and their impact. Write the scope and `session.json` to `~/.native-routed/notes/<topic>/` as `native-routed-codex` describes.
2. Create the integration branch. When the project closes work through pull requests, or the user asks for one, open a draft PR after the first merge (a branch with no commits ahead of the main branch can't open one), marked as closing the spec and its tickets. Dispatch each ready ticket to a fresh worker with: ticket id, goal, acceptance checks, full baseline SHA, notes path and the project rules' paths. Record each worktree in `session.json`.
3. When resuming a worktree, check its actual baseline and uncommitted changes. Adjust branches per project convention; keep existing changes and never overwrite state with an unconditional reset.
4. Each implementer confirms its worktree is based on the integration branch, follows the test discipline, commits and logs progress per project convention, runs the relevant and new tests, merges the integration branch tip into its own branch, and reports actual changes and deviations.
5. The merger merges in a separate candidate tree and runs the project's required build, tests and receipt checks. Only after they pass does it update the integration branch and the frontier.
6. When every ticket is done, run the independent review, fix and re-check, then close out: mark the draft PR ready for review if there is one; otherwise resolve each ticket the way the project's tracker closes work and report the integration branch. Remove the ticket worktrees.

On every continue or resume, read the notes, then check each worktree's `git log` and `git status` first. Subagents from an earlier session are gone; re-dispatch unfinished tickets to fresh workers.

## Acceptance

Check each ticket's commits, acceptance checks, diff and test log exit code. Use the project's receipt mechanism when it has one; otherwise keep reproducible test commands, logs and exit codes.

Handle draft PRs, ticket closing, branch merges, pushes and worktree cleanup per the project's rules, within the user's existing authorization. Report actual results, deviations and anything unverified.

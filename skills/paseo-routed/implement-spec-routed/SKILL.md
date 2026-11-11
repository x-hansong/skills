---
name: implement-spec-routed
description: "Implement a spec and its dependency graph of tickets through Paseo: this session orchestrates the ready frontier, the roster's worker implements and merges each ticket, the roster's reviewer reviews and diagnoses. Follows the current project's integration, testing and delivery rules."
argument-hint: "[--roster <name>] <spec path or ticket source>"
disable-model-invocation: true
license: MIT
compatibility: "Claude Code or Codex. Requires everything paseo-routed requires."
metadata:
  author: x-hansong
---

# Routed spec implementation

**Spec:** $ARGUMENTS

Load the `paseo-routed` skill and apply its roster resolution, dispatch, recovery, acceptance and report rules, test discipline and review method to this run. Pass `--roster` through to roster resolution. Reply in the user's language.

The input is a spec, its tickets and how they are tracked. Without a ticket graph, when the user just wants a task or plan carried out, use `implement-routed`. When tickets really must be closed, first settle where they live and how they are closed.

## Roles

| Step | Who |
| --- | --- |
| Orchestrator | This session schedules the frontier and checks real diffs, test evidence and each ticket's acceptance checks |
| Exploration | Read-only worker on demand; notes go to the shared directory outside the repo |
| Implementation | A fresh worker per ticket, each in its own worktree and branch |
| Merge | Another worker, merging and verifying per the project's integration rules |
| Final review | `paseo-advisor` with the roster's `reviewer` profile, read-only, over the integration branch; pass the full baseline SHA, the spec and the ticket source |
| Review fixes | A fresh worker; implementer and reviewer are always different agents |
| Same failure a second time | `paseo-committee` for an independent diagnosis and plan |

## Task graph

The tickets are not a list of steps but a task graph with blocking edges, so there is always a frontier of tickets ready to start. Start every ticket's worker as soon as it is on the frontier, in the background where the host allows, and start the next ones whenever a merge moves the frontier.

Every agent starts with a fresh context. Keep messages to and from agents short: pass pointers to the spec, the tickets, the notes and earlier commits instead of restating them.

## Tickets, baseline and parallelism

1. Read the project's `AGENTS.md` (or `CLAUDE.md`) and its ticket, testing, integration and handoff conventions. Check existing changes and record the full baseline SHA. Verify the baseline with the project's own checks and note pre-existing failures and their impact.
2. Create the integration branch. When the project closes work through pull requests, or the user asks for one, open a draft PR after the first merge (a branch with no commits ahead of the main branch can't open one), marked as closing the spec and its tickets. Dispatch each ready ticket to a fresh worker with: ticket id, goal, acceptance checks, full baseline SHA, workspace, shared notes path and the project rules' paths.
3. When creating or resuming a worktree, check its actual baseline and uncommitted changes. Adjust branches per project convention; keep existing changes and never overwrite state with an unconditional reset.
4. Each implementer confirms its worktree is based on the integration branch, follows the test discipline, commits and logs progress per project convention, runs the relevant and new tests, merges the integration branch tip into its own branch, and reports actual changes and deviations.
5. The merger merges in a separate candidate tree and runs the project's required build, tests and receipt checks. Only after they pass does it update the integration branch and the frontier.
6. When every ticket is done, run the independent review, fix and re-check, then close out: mark the draft PR ready for review if there is one; otherwise resolve each ticket the way the project's tracker closes work and report the integration branch. Remove the ticket worktrees.

On every continue or resume, check the running agents and each worktree's `git log` and `git status` first.

## Acceptance

Check each ticket's commits, acceptance checks, diff and test log exit code. Use the project's receipt mechanism when it has one; otherwise keep reproducible test commands, logs and exit codes.

Handle draft PRs, ticket closing, branch merges, pushes and worktree cleanup per the project's rules, within the user's existing authorization. Report actual results, deviations and anything unverified.

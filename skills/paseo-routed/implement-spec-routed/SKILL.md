---
name: implement-spec-routed
description: "Implement a spec and its dependency graph of tickets through Paseo: this session orchestrates the ready frontier, the roster's worker implements and merges each ticket, the roster's reviewer reviews and diagnoses. Follows the current project's integration, testing and delivery rules."
argument-hint: "[--roster <name>] <spec path or ticket source>"
disable-model-invocation: true
license: MIT
compatibility: "Claude Code or Codex. Requires everything paseo-routed requires, plus the implement-spec, tdd and code-review skills (npx skills add mattpocock/skills --skill implement-spec --skill tdd --skill code-review)."
metadata:
  author: x-hansong
---

# Routed spec implementation

**Spec:** $ARGUMENTS

Load the `implement-spec` skill and keep its ticket dependency graph, ready frontier, per-ticket worktrees, integration branch and delivery requirements. Then load the `paseo-routed` skill and apply its roster resolution, dispatch, recovery and acceptance rules to this run. Load a skill with the Skill tool, or, on a host without one, open its `SKILL.md` from your skills list. The overrides below win over `implement-spec`. Pass `--roster` through to roster resolution.

The input is a spec, its tickets and how they are tracked. Without a ticket graph, when the user just wants a task or plan carried out, use `implement-routed`. When tickets really must be closed, first settle where they live and how they are closed.

## Role overrides

| `implement-spec` role or step | Here |
| --- | --- |
| Orchestrator | This session schedules the frontier and checks real diffs, test evidence and each ticket's acceptance checks |
| Exploration subagent | Read-only worker on demand; notes go to the shared directory outside the repo |
| Implementer subagent | A fresh worker per ticket, each in its own worktree and branch |
| Merger subagent | Another worker, merging and verifying per the project's integration rules |
| `code-review` step | `paseo-advisor` with the roster's `reviewer` profile, read-only, over the integration branch; pass the full baseline SHA, the spec and the ticket source |
| Review fixes | A fresh worker; implementer and reviewer are always different agents |
| Same failure a second time | `paseo-committee` for an independent diagnosis and plan |

## Tickets, baseline and parallelism

1. Read the project's `AGENTS.md` (or `CLAUDE.md`) and its ticket, testing, integration and handoff conventions. Check existing changes and record the full baseline SHA. Verify the baseline with the project's own checks and note pre-existing failures and their impact.
2. Create the integration branch. Dispatch each ready ticket to a fresh worker with: ticket id, goal, acceptance checks, full baseline SHA, workspace, shared notes path and the project rules' paths.
3. When creating or resuming a worktree, check its actual baseline and uncommitted changes. Adjust branches per project convention; keep existing changes and never overwrite state with an unconditional reset.
4. Each implementer uses the `tdd` skill, commits and logs progress per project convention, runs the relevant and new tests, and reports actual changes and deviations.
5. The merger merges in a separate candidate tree and runs the project's required build, tests and receipt checks. Only after they pass does it update the integration branch and the frontier.
6. When every ticket is done, run the independent review, fix and re-check, then close out with `implement-spec`'s delivery steps and the project's tracking.

On every continue or resume, check the running agents and each worktree's `git log` and `git status` first.

## Acceptance

Check each ticket's commits, acceptance checks, diff and test log exit code. Use the project's receipt mechanism when it has one; otherwise keep reproducible test commands, logs and exit codes.

Handle draft PRs, ticket closing, branch merges, pushes and worktree cleanup per the project's rules, within the user's existing authorization. Report actual results, deviations and anything unverified.

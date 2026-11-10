---
name: native-implement-routed-codex
description: "Implement a task description, agreed plan, spec or single ticket in Codex without Paseo: this session orchestrates, a worker subagent implements and merges, a reviewer subagent on a stronger model reviews. No tickets needed; for a dependency graph of tickets use native-implement-spec-routed-codex."
argument-hint: "[--worker <model>[/<effort>]] [--reviewer <model>[/<effort>]] <task, plan or spec path, or ticket>"
disable-model-invocation: true
license: MIT
compatibility: "Codex only. Requires everything native-routed-codex requires."
metadata:
  author: x-hansong
---

# Native routed implementation (Codex)

**Task:** $ARGUMENTS

Load the `native-routed-codex` skill and apply its model resolution, dispatch, recovery and acceptance rules, test discipline and review method to this run. Pass `--worker` and `--reviewer` through to model resolution. Reply in the user's language.

## Input and scope

Accepts a free description, a plan agreed in conversation, a plan or spec path, or a single ticket. Given a ticket reference, fetch it from the project's tracker and state its title before starting; ask when the reference is ambiguous. Without a ticket, the confirmed requirement and the scope notes are the source of truth. Multiple tickets with dependencies go to `native-implement-spec-routed-codex`.

Before starting, write the scope, checkable acceptance checks and the full baseline SHA to `~/.native-routed/notes/<topic>/`, with `session.json` as `native-routed-codex` describes. Track each work unit's status, commit SHA, test evidence and acceptance result there.

## Roles

| Step | Who |
| --- | --- |
| Orchestration | This session orchestrates, dispatches and accepts; a worker subagent implements |
| Tests | The worker follows the test discipline within the test boundary the brief sets: which seams get a test first, and which checks are relevant |
| Final review | A fresh reviewer subagent on the reviewer model, read-only, baseline to candidate; pass this requirement and the acceptance notes |
| Review fixes | A fresh worker, then re-check |
| Merge | With several work units, another worker merges and re-runs the relevant checks |
| Exploration | Read-only worker on demand; notes go to the notes directory |
| Same failure a second time | The committee from `native-routed-codex` |

A single unit, or units sharing files, run serially. Each worker commits to its own branch, or to the current branch when it works in the main tree. Independent units with disjoint files may run in parallel, each in its own worktree. The notes are the progress log for ticket-less work.

## Project rules

Read the repo's `AGENTS.md` (or `CLAUDE.md`) and its development, testing, parallel-work and handoff conventions, and check `git status` first. Use the baseline checks, test selection, build, receipt and doc-update mechanisms the project actually has.

Acceptance checks real commits, the diff, the acceptance checks and test results. Branching, committing, merging, pushing and cleanup follow the project's rules and the user's authorization; this skill prescribes no project script, main branch or default push flow.

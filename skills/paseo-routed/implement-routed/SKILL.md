---
name: implement-routed
description: "Implement a task description, agreed plan, spec or single ticket through Paseo: this session orchestrates, the roster's worker implements and merges, the roster's reviewer reviews. No tickets needed; for a dependency graph of tickets use implement-spec-routed."
argument-hint: "[--roster <name>] <task, plan or spec path, or ticket>"
disable-model-invocation: true
license: MIT
compatibility: "Claude Code or Codex. Requires everything paseo-routed requires."
metadata:
  author: x-hansong
---

# Routed implementation

**Task:** $ARGUMENTS

Load the `paseo-routed` skill and apply its roster resolution, dispatch, recovery, acceptance and report rules, test discipline and review method to this run. Pass `--roster` through to roster resolution. Reply in the user's language.

## Input and scope

Accepts a free description, a plan agreed in conversation, a plan or spec path, or a single ticket. Given a ticket reference, fetch it from the project's tracker and state its title before starting; ask when the reference is ambiguous. Without a ticket, the confirmed requirement and the shared acceptance notes are the source of truth. Multiple tickets with dependencies go to `implement-spec-routed`.

Before starting, write the scope, checkable acceptance checks and the full baseline SHA to the shared notes outside the repo. Track each work unit's status, commit SHA, test evidence and acceptance result there.

## Roles

| Step | Who |
| --- | --- |
| Orchestration | This session orchestrates, dispatches and accepts; the roster's `worker` implements |
| Tests | The worker follows the test discipline within the test boundary the brief sets: which seams get a test first, and which checks are relevant |
| Final review | `paseo-advisor` with the roster's `reviewer` profile, read-only, baseline to candidate; pass this requirement and the acceptance notes |
| Review fixes | A fresh worker, then re-check |
| Merge | With several work units, another worker merges and re-runs the relevant checks |
| Exploration | Read-only worker on demand; notes go to the shared directory |

A single unit, or units sharing files, run serially. Each worker commits to its own branch, or to the current branch when it works in the main tree. Independent units with disjoint files may run in parallel, each in its own worktree and branch. The shared notes are the progress log for ticket-less work.

## Project rules

Read the repo's `AGENTS.md` (or `CLAUDE.md`) and its development, testing, parallel-work and handoff conventions, and check `git status` first. Use the baseline checks, test selection, build, receipt and doc-update mechanisms the project actually has.

Acceptance checks real commits, the diff, the acceptance checks and test results. Branching, committing, merging, pushing and cleanup follow the project's rules and the user's authorization; this skill prescribes no project script, main branch or default push flow.

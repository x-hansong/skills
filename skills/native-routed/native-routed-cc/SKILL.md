---
name: native-routed-cc
description: "Run a task in Claude Code with a division of labour and no Paseo: this session designs and orchestrates, a worker subagent explores, researches, implements, merges and fixes, and a separate reviewer subagent on a stronger model reviews and diagnoses. Uses Claude Code's built-in Agent tool only. Use when the user asks for routed or delegated execution inside Claude Code without Paseo. No spec or tickets required."
argument-hint: "[--worker <model>] [--reviewer <model>] <task, plan path or ticket reference>"
license: MIT
compatibility: "Claude Code only, inside a git repository. Optional ~/.native-routed/config.yaml written by native-routed-setup-cc; the code-review skill for reviews."
metadata:
  author: x-hansong
---

# Native routed execution (Claude Code)

**Task:** $ARGUMENTS

The task can be a description, a plan just agreed in conversation, a file path, or a ticket. Reply in the user's language.

## Roles

| Role | Does | Never does |
| --- | --- | --- |
| This session (orchestrator) | Designs the plan: goal, boundaries, architecture, trade-offs, acceptance criteria. Splits work, writes briefs, dispatches, checks results, wraps up. | Explore, research or implement the task itself, or hand design to another agent. |
| `worker` | Read-only exploration, web research, implementation, merging, review fixes. | Review its own work. |
| `reviewer` | Read-only review and hard diagnosis; one of the two committee members. | Write project files. |

Every role is a subagent started with the Agent tool. Which model plays each role is resolved in [models](references/models.md). How to start, wait on and pass skills to subagents is in [dispatch](references/dispatch.md).

## Steps

1. **Preflight.** Confirm this is a git repository (`git rev-parse --show-toplevel`) and record the full baseline SHA. If it isn't, stop and say so. Resolve the models per [models](references/models.md).
2. **Scope.** Restate the scope and a **checkable done-condition** in two or three sentences, and write them to `~/.native-routed/notes/<topic>/scope.md`, outside the repo. Record the resolved models there. Write `session.json` in the same directory as [dispatch](references/dispatch.md#session-record) describes, so `native-watch-cc` can find this run. Ask the user only when the scope is too vague to write a done-condition; otherwise proceed on sensible defaults and say which ones.
3. **Split into work units**, each with a goal, acceptance checks and a file scope.
   - When the code or docs need to be understood first, or the web searched, dispatch the worker for read-only exploration or research, then split the implementation from its evidence. A pure research task is accepted on its deliverable.
   - One unit, or units touching the same files: one worker does them serially in the current working tree.
   - Independent units with disjoint files: one worker per unit, each started with `isolation: "worktree"`. A separate worker merges the branches and re-runs the relevant tests; no conflicts is not the same as verified. Add every worktree to `session.json`.
4. **Brief.** A brief contains only: goal, done-condition, full baseline SHA, notes path, and the project rules to follow. Point to documents instead of restating them. A subagent sees none of this conversation, so the brief must stand on its own. Require the agent to:
   - for exploration and research: change no project files and create no worktree or commit; deliver sources or file locations, what was searched, the evidence behind each conclusion and open questions, separating fact from inference;
   - for implementation: commit step by step, run the relevant tests before each commit, and report done only when they all pass;
   - report actual changes and deviations, not just a summary;
   - append progress to the notes with `cat >> <notes file> <<'EOF'` without re-reading the file; "only touch file X" in a brief never excludes the notes;
   - watch long jobs to a terminal state itself, and return only when a decision is needed or the work is done; intermediate progress goes to the notes.

   State three classes of stop condition in the brief, so the agent routes them without asking each time:

   | Situation | Handling |
   | --- | --- |
   | Network or transport error (stateless fetch failure, timeout) | Retry per the retry rule; stop when retries are exhausted |
   | Business result (node failure, failed stats, PARTIAL) | Record the error code; exclude or continue per the agreed rule |
   | Write request with uncertain outcome, or an uncovered protocol error | Reconcile read-only first, then stop and report |

   When a project skill already has an error-code table, cite it instead. Before a brief relies on a skill that performs writes, verify its request headers and required fields against the calling code; a new or changed write skill is reviewed by the reviewer before a worker runs it.
5. **Review.** After implementation, start a fresh reviewer subagent on the reviewer model with a read-only brief: load the `code-review` skill and review from the baseline SHA to the candidate, with the confirmed requirement and the notes as the Spec source. Afterwards check `git status` in the reviewed tree shows no changes. Exploration and research are checked by this session against their evidence and are not auto-reviewed; call the reviewer for them only for a targeted review, hard diagnosis, or when the user asks. Author and reviewer are never the same agent. Hand P0–P2 findings to a **fresh** worker and re-check after the fix; if the fix touched production code paths, have a fresh reviewer review the fix diff or say in the report that it was not re-reviewed. List P3 findings for the user to decide; do not auto-fix them.
6. **Repeated failure.** When the same failure happens a second time, don't let the implementer retry in place. Convene the committee: start both committee subagents in parallel, read-only, each with the failure evidence, the notes path and the baseline SHA. Brief one to dig for the root cause and the other to challenge the current approach; each returns a diagnosis and a plan. Compare the two, pick or merge a plan, record it in the notes, then dispatch a fresh worker.
7. **Resume.** Subagents don't outlive this session. On every "continue" or after a restart, read `~/.native-routed/notes/<topic>/`, then check `git log` and `git status` in the main tree and every worktree in `session.json` before doing anything else.

## Acceptance

Don't accept an agent's summary on its own word. For exploration and research, check sources, whether the evidence supports the conclusions, the acceptance checks and open questions. For implementation, check that the commits exist, the acceptance checks pass, the test log exits 0, and the diff matches the brief. Remove the worktrees this task created once their branches are merged or abandoned. Report to the user the actual changes or findings, deviations, and anything left unverified.

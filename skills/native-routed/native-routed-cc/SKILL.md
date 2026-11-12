---
name: native-routed-cc
description: "Run a task in Claude Code with a division of labour and no Paseo: this session designs and orchestrates, a worker subagent explores, researches, implements, merges and fixes, and a separate reviewer subagent on a stronger model reviews and diagnoses. Uses Claude Code's built-in Agent tool only. Use when the user asks for routed or delegated execution inside Claude Code without Paseo. No spec or tickets required."
argument-hint: "[--worker <model>[/<effort>]] [--reviewer <model>[/<effort>]] [--budget <budget>] <task, plan path or ticket reference>"
license: MIT
compatibility: "Claude Code only, inside a git repository. Optional ~/.native-routed/config.yaml written by native-routed-setup-cc."
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
| `reviewer` | Read-only review and hard diagnosis; its model usually also sits on the committee. | Write project files. |

Every role is a subagent started with the Agent tool. Which model plays each role is resolved in [models](references/models.md). How to start, wait on and pass methods to subagents is in [dispatch](references/dispatch.md).

## Steps

1. **Preflight.** Confirm this is a git repository (`git rev-parse --show-toplevel`) and record the full baseline SHA. If it isn't, stop and say so. Resolve the models per [models](references/models.md).
2. **Scope.** In your first reply, tell the user in your own words the goal, the problem it solves and the smallest change you expect to meet it, then carry on without waiting; if the evidence rules out what the user asked for, show it and stop. Restate the scope and a **checkable done-condition** in two or three sentences, and write them to `~/.native-routed/notes/<topic>/scope.md`, outside the repo. Record the resolved models there, and copy [test discipline](references/tests.md), [review method](references/review.md) and [design principles](references/principles.md) into the same directory. Write `session.json` in the same directory as [dispatch](references/dispatch.md#session-record) describes, so `native-watch-cc` can find this run. Ask the user only when the scope is too vague to write a done-condition. Keep `progress.md` in the same directory as the resume point: intent, current step, progress and what is verified, agents and worktrees still live, next steps, key files and gotchas; rewrite it at every unit boundary.
   At any later fork, first ask whether running something would answer it (behaviour, output, layout, timing, whether a check separates); if so, dispatch a worker to try it and let the result decide. Ask the user only for a product or preference call no experiment settles. Otherwise proceed on a sensible default, and say which one and what the user could tell you to do instead.
3. **Split into work units**, each with a goal, acceptance checks and a file scope.
   - Several similar units: take the first through brief, implementation, review and acceptance before dispatching the rest, so a flaw in the brief costs one agent, not all of them.
   - When the code or docs need to be understood first, or the web searched, dispatch the worker for read-only exploration or research, then split the implementation from its evidence. A pure research task is accepted on its deliverable.
   - One unit, or units touching the same files: one worker does them serially in the current working tree.
   - Independent units with disjoint files: one worker per unit, each started with `isolation: "worktree"`. A separate worker merges the branches and re-runs the relevant tests; no conflicts is not the same as verified. Add every worktree to `session.json`.
4. **Brief.** A brief contains only: goal, done-condition, full baseline SHA, notes path, the decided design, and the project rules to follow. Point to documents instead of restating them. For implementation, the decided design names, before the worker writes any logic: the file paths, the data shape and its organizing structure (a state machine over scattered flags, a table over branching, a typed model over repeated shape assumptions), the key trade-offs already made, and the boundary rules (what may be written, validation, error handling). Read the design principles copy in the notes before writing it, and name in the brief each principle that shaped it. The worker follows the design; to change it, the worker reports back first. A subagent sees none of this conversation, so the brief must stand on its own. Require the agent to:
   - for exploration and research: change no project files and create no worktree or commit; deliver sources or file locations, what was searched, the evidence behind each conclusion and open questions, separating fact from inference;
   - for implementation: follow the test discipline copy in the notes within the test boundary the brief sets, commit step by step, run the relevant tests before each commit, and report done only when they all pass;
   - report actual changes and deviations, not just a summary;
   - append progress to the notes with `cat >> <notes file> <<'EOF'` without re-reading the file; "only touch file X" in a brief never excludes the notes;
   - watch long jobs to a terminal state itself, and return only when a decision is needed or the work is done; intermediate progress goes to the notes.

   A fresh agent that takes over or follows up earlier work (a fix round, a retry, a changed scope) gets a consolidated brief: the original brief, every later directive, and the prior agent's report and branch. When the user changes the scope while an agent runs, tell that agent to stop or narrow to what still holds and commit it; give the new scope to a fresh agent instead of chaining instructions onto the old one, which silently drops directives.

   State three classes of stop condition in the brief, so the agent routes them without asking each time:

   | Situation | Handling |
   | --- | --- |
   | Network or transport error (stateless fetch failure, timeout) | Retry per the retry rule; stop when retries are exhausted |
   | Business result (node failure, failed stats, PARTIAL) | Record the error code; exclude or continue per the agreed rule |
   | Write request with uncertain outcome, or an uncovered protocol error | Reconcile read-only first, then stop and report |

   When a project skill already has an error-code table, cite it instead. Before a brief relies on a skill that performs writes, verify its request headers and required fields against the calling code; a new or changed write skill is reviewed by the reviewer before a worker runs it.
5. **Review.** After implementation, start a fresh reviewer subagent on the reviewer model with a read-only brief: follow the review method and design principles copies in the notes, from the baseline SHA to the candidate, with the confirmed requirement and the notes as the Spec source. Afterwards check `git status` in the reviewed tree shows no changes. Exploration and research are checked by this session against their evidence and are not auto-reviewed; call the reviewer for them only for a targeted review, hard diagnosis, or when the user asks. Author and reviewer are never the same agent. Before acting on a P0–P2 behaviour or Spec finding, rerun its command yourself: keep it only when the output shows the failure, otherwise move it to the user list with the output you got. Hand the kept P0–P2 findings to a **fresh** worker; the fix is done when the same commands print the required output. Extras added because they might help, and changes motivated by a hypothesis the evidence refuted, are reverted, not shipped. If the fix touched production code paths, have a fresh reviewer review the fix diff or say in the report that it was not re-reviewed. List P3 and Unproven findings for the user to decide; do not auto-fix them.
6. **Retry and repeated failure.** Retry a failed agent by cause: a smaller scope after a context or memory limit, the same brief after a dropped connection, a different model after a tool error, per [model rejected mid-run](references/models.md#model-rejected-mid-run). When the same failure happens a second time, or two retries didn't help, don't let the implementer retry in place. Write down the premise the failed attempts share, then convene the committee: start one read-only subagent per committee entry, all in parallel, each with the shared premise, the failure evidence, the notes path and the baseline SHA. Alternate two briefs down the list, the first member testing the premise directly and digging for the root cause and the second challenging the current approach; each returns a diagnosis and a plan. Compare them, pick or merge a plan, record it in the notes, then dispatch a fresh worker.
7. **Resume.** Subagents don't outlive this session. On every "continue" or after a restart, read `~/.native-routed/notes/<topic>/`, starting with `progress.md`, then check `git log` and `git status` in the main tree and every worktree in `session.json` before doing anything else. The notes and git history are authoritative: don't redo verified work, but re-verify on the real artifact any inherited claim the next step relies on.

## Acceptance

Don't accept an agent's summary on its own word. For exploration and research, check sources, whether the evidence supports the conclusions, the acceptance checks and open questions. For implementation, check that the commits exist, the acceptance checks pass, the test log exits 0, and the diff matches the brief. Send back work that drifts past the brief: keep only what blocks this task and record the rest in the notes as follow-ups. A review verdict covers one head SHA; a later commit needs a new verdict. Remove the worktrees this task created once their branches are merged or abandoned. Before removing one, list what `git status --ignored` shows there that this task produced (run outputs, baselines, private data) and copy it to the main checkout or the notes directory; removing a worktree deletes its ignored files too.

Give every acceptance check one verdict: **verified** (you saw the evidence on the real artifact), **not verified** (the evidence shows it fails) or **inconclusive** (no evidence, or evidence from the wrong surface). Inconclusive is not a pass.

## Report

- Open with the user's goal in one sentence, then the actual changes or findings, deviations, model fallbacks, and every check that isn't verified.
- Label each claim in the same sentence: measured (you ran or read it this session), inferred, or a guess. Never hand the user a check you could have run.
- Name each design principle that shaped a decision and the choice it changed; cite only principles read this run.
- Account for every agent this run started: done, replaced, or absorbed into another agent's scope.
- Link only to files, commits and URLs this run produced or read.

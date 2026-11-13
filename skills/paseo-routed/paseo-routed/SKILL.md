---
name: paseo-routed
description: "Run a task through Paseo with a division of labour: this session designs and orchestrates, a worker agent explores, researches, implements, merges and fixes, and a separate reviewer agent reviews and diagnoses. Which Paseo profiles play worker and reviewer comes from a switchable roster. Use when the user asks for routed or delegated execution, wants work dispatched to Paseo agents, or names a roster. No spec or tickets required."
argument-hint: "[--roster <name>] <task, plan path or ticket reference>"
license: MIT
compatibility: "Claude Code or Codex. Requires the Paseo CLI and a running daemon (npm i -g @getpaseo/cli), the paseo / paseo-advisor / paseo-committee skills (npx skills add getpaseo/paseo), and ~/.paseo-routed/config.yaml created by setup-paseo-routed."
metadata:
  author: x-hansong
---

# Paseo routed execution

**Task:** $ARGUMENTS

The task can be a description, a plan just agreed in conversation, a file path, or a ticket. Reply in the user's language.

## Roles

| Role | Does | Never does |
| --- | --- | --- |
| This session (orchestrator) | Designs the plan: goal, boundaries, architecture, trade-offs, acceptance criteria. Splits work, writes briefs, dispatches, checks results, wraps up. | Explore, research or implement the task itself, or hand design to another agent. |
| `worker` | Read-only exploration, web research, implementation, merging, review fixes. | Review its own work. |
| `reviewer` | Read-only review and hard diagnosis, `paseo-committee`. | Write project files. |

Which Paseo profile plays each role comes from the roster. See [roster resolution](references/roster.md). Never fall back to this host's built-in subagents. If the roster or a profile can't be resolved, stop and tell the user.

## Steps

1. **Resolve the roster.** Follow [roster resolution](references/roster.md): read `~/.paseo-routed/config.yaml`, pick the roster (`--roster <name>` or the user naming one in the request, else `default_roster`), look up both profiles with `list_profiles`. Load the `paseo` skill for tool usage and [Paseo access](references/paseo-access.md) for how to expand a profile into `create_agent` settings.
2. **Scope.** In your first reply, tell the user in your own words the goal, the problem it solves and the smallest change you expect to meet it, then carry on without waiting; if the evidence rules out what the user asked for, show it and stop. Restate the scope and a **checkable done-condition** in two or three sentences, and write them to a shared notes directory outside the repo: `<notes_dir>/<topic>/`. Record the resolved roster and profile names there, and copy [test discipline](references/tests.md), [review method](references/review.md) and [design principles](references/principles.md) into the same directory. Ask the user only when the scope is too vague to write a done-condition. Keep `progress.md` in the same directory as the resume point: intent, current step, progress and what is verified, agents and worktrees still live, next steps, key files and gotchas; rewrite it at every unit boundary.
   At any later fork, first ask whether running something would answer it (behaviour, output, layout, timing, whether a check separates); if so, dispatch a worker to try it and let the result decide. Ask the user only for a product or preference call no experiment settles. Otherwise proceed on a sensible default, and say which one and what the user could tell you to do instead.
3. **Split into work units**, each with a goal, acceptance checks and a file scope.
   - Several similar units: take the first through brief, implementation, review and acceptance before dispatching the rest, so a flaw in the brief costs one agent, not all of them.
   - When the code or docs need to be understood first, or the web searched, dispatch the worker for read-only exploration or research, then split the implementation from its evidence. A pure research task is accepted on its deliverable.
   - One unit, or units touching the same files: one worker does them serially.
   - Independent units with disjoint files: one worker per unit, each in its own worktree and branch. A separate worker merges and re-runs the relevant tests; no conflicts is not the same as verified.
4. **Brief.** A brief contains only: goal, done-condition, full baseline SHA (when a repo is involved), shared notes path, the decided design, and the project rules to follow. Point to documents instead of restating them. Read every SHA and branch fact in a brief from an explicit ref such as `git rev-parse origin/<branch>`; `HEAD` is whatever branch the checkout happens to sit on, possibly someone else's. For implementation, the decided design names, before the worker writes any logic: the file paths, the data shape and its organizing structure (a state machine over scattered flags, a table over branching, a typed model over repeated shape assumptions), the key trade-offs already made, and the boundary rules (what may be written, validation, error handling). Read the design principles copy in the notes before writing it, and name in the brief each principle that shaped it. The worker follows the design; to change it, the worker reports back first. Require the agent to:
   - for exploration and research: change no project files and create no worktree or commit; deliver sources or file locations, what was searched, the evidence behind each conclusion and open questions, separating fact from inference;
   - for implementation: follow the test discipline copy in the notes within the test boundary the brief sets, commit step by step, run the relevant tests before each commit, and report done only when they all pass;
   - report actual changes and deviations, not just a summary;
   - append progress to the shared notes with `cat >> <notes file> <<'EOF'` without re-reading the file; "only touch file X" in a brief never excludes the shared notes;
   - watch long jobs to a terminal state within the same turn, blocking or polling at intervals of 60 seconds or more; once the turn ends, no background process or monitor wakes the agent again. Message back only when a decision is needed or the work is done; intermediate progress goes to the notes.

   A fresh agent that takes over or follows up earlier work (a fix round, a retry, a changed scope) gets a consolidated brief: the original brief, every later directive, and the prior agent's report and branch. When the user changes the scope while an agent runs, tell that agent to stop or narrow to what still holds and commit it; give the new scope to a fresh agent instead of chaining instructions onto the old one, which silently drops directives.

   State three classes of stop condition in the brief, so the agent routes them without asking each time:

   | Situation | Handling |
   | --- | --- |
   | Network or transport error (stateless fetch failure, timeout) | Retry per the retry rule; stop when retries are exhausted |
   | Business result (node failure, failed stats, PARTIAL) | Record the error code; exclude or continue per the agreed rule |
   | Write request with uncertain outcome, or an uncovered protocol error | Reconcile read-only first, then stop and report |

   When a project skill already has an error-code table, cite it instead. Before a brief relies on a skill that performs writes, verify its request headers and required fields against the calling code; a new or changed write skill is reviewed by the reviewer before a worker runs it.
5. **Review.** After implementation, run a read-only review: `/paseo-advisor --profile <reviewer profile>` with a brief that points to the review method and design principles copies in the notes and gives the baseline SHA, the candidate, the Spec source and the project's standards files. Exploration and research are checked by this session against their evidence and are not auto-reviewed; call the reviewer for them only for a targeted review, hard diagnosis, or when the user asks. Author and reviewer are never the same agent. Before acting on a P0–P2 behaviour or Spec finding, rerun its command yourself: keep it only when the output shows the failure, otherwise move it to the user list with the output you got. Hand the kept P0–P2 findings to a **fresh** worker; the fix is done when the same commands print the required output. Extras added because they might help, and changes motivated by a hypothesis the evidence refuted, are reverted, not shipped. If the fix touched production code paths, have the reviewer review the fix diff or say in the report that it was not re-reviewed. List P3 and Unproven findings for the user to decide; do not auto-fix them.
6. **Retry and repeated failure.** Retry a failed agent by cause: a smaller scope after a context or memory limit, the same brief after a dropped connection, and after a tool error, check the profile's settings once, then stop and tell the user; never substitute another profile. When the same failure happens a second time, or two retries didn't help, don't let the implementer retry in place. Write down the premise the failed attempts share, then run `/paseo-committee` with that premise and the failure evidence, asking it to test the premise directly before proposing another fix.
7. **Resume.** On every "continue" or after a restart, read `progress.md`, list the agents still running, then check `git log` and `git status` in each worktree. The notes and git history are authoritative: don't redo verified work, but re-verify on the real artifact any inherited claim the next step relies on.

## Waiting

Wait on `notifyOnFinish` notifications; no heartbeat by default. Only when this host can't be woken in the background (Codex, for example) set a fallback heartbeat of 50 minutes or more, and delete it when the task ends.

## Acceptance

Don't accept an agent's summary on its own word. For exploration and research, check sources, whether the evidence supports the conclusions, the acceptance checks and open questions. For implementation, check that the commits exist, the acceptance checks pass, the test log exits 0, and the diff matches the brief. Send back work that drifts past the brief: keep only what blocks this task and record the rest in the notes as follow-ups. A review verdict covers one head SHA; a later commit needs a new verdict. Clean up the worktrees this task created. Before removing one, list what `git status --ignored` shows there that this task produced (run outputs, baselines, private data) and copy it to the main checkout or the notes directory; removing a worktree deletes its ignored files too.

Give every acceptance check one verdict: **verified** (you saw the evidence on the real artifact), **not verified** (the evidence shows it fails) or **inconclusive** (no evidence, or evidence from the wrong surface). Inconclusive is not a pass.

When the roster sets `compare: true`, also follow the comparison log rule in [roster resolution](references/roster.md).

## Report

- Open with the user's goal in one sentence, then the actual changes or findings, deviations, and every check that isn't verified.
- Label each claim in the same sentence: measured (you ran or read it this session), inferred, or a guess. Never hand the user a check you could have run.
- Name each design principle that shaped a decision and the choice it changed; cite only principles read this run.
- Account for every agent this run started: done, replaced, or absorbed into another agent's scope.
- Link only to files, commits and URLs this run produced or read.

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
2. **Scope.** Restate the scope and a **checkable done-condition** in two or three sentences, and write them to a shared notes directory outside the repo: `<notes_dir>/<topic>/`. Record the resolved roster and profile names there, and copy [test discipline](references/tests.md) and [review method](references/review.md) into the same directory. Ask the user only when the scope is too vague to write a done-condition; otherwise proceed on sensible defaults and say which ones.
3. **Split into work units**, each with a goal, acceptance checks and a file scope.
   - When the code or docs need to be understood first, or the web searched, dispatch the worker for read-only exploration or research, then split the implementation from its evidence. A pure research task is accepted on its deliverable.
   - One unit, or units touching the same files: one worker does them serially.
   - Independent units with disjoint files: one worker per unit, each in its own worktree and branch. A separate worker merges and re-runs the relevant tests; no conflicts is not the same as verified.
4. **Brief.** A brief contains only: goal, done-condition, full baseline SHA (when a repo is involved), shared notes path, and the project rules to follow. Point to documents instead of restating them. Require the agent to:
   - for exploration and research: change no project files and create no worktree or commit; deliver sources or file locations, what was searched, the evidence behind each conclusion and open questions, separating fact from inference;
   - for implementation: follow the test discipline copy in the notes within the test boundary the brief sets, commit step by step, run the relevant tests before each commit, and report done only when they all pass;
   - report actual changes and deviations, not just a summary;
   - append progress to the shared notes with `cat >> <notes file> <<'EOF'` without re-reading the file; "only touch file X" in a brief never excludes the shared notes;
   - watch long jobs to a terminal state itself, and message back only when a decision is needed or the work is done; intermediate progress goes to the notes.

   State three classes of stop condition in the brief, so the agent routes them without asking each time:

   | Situation | Handling |
   | --- | --- |
   | Network or transport error (stateless fetch failure, timeout) | Retry per the retry rule; stop when retries are exhausted |
   | Business result (node failure, failed stats, PARTIAL) | Record the error code; exclude or continue per the agreed rule |
   | Write request with uncertain outcome, or an uncovered protocol error | Reconcile read-only first, then stop and report |

   When a project skill already has an error-code table, cite it instead. Before a brief relies on a skill that performs writes, verify its request headers and required fields against the calling code; a new or changed write skill is reviewed by the reviewer before a worker runs it.
5. **Review.** After implementation, run a read-only review: `/paseo-advisor --profile <reviewer profile>` with a brief that points to the review method copy in the notes and gives the baseline SHA, the candidate, the Spec source and the project's standards files. Exploration and research are checked by this session against their evidence and are not auto-reviewed; call the reviewer for them only for a targeted review, hard diagnosis, or when the user asks. Author and reviewer are never the same agent. Hand P0–P2 findings to a **fresh** worker and re-check after the fix; if the fix touched production code paths, have the reviewer review the fix diff or say in the report that it was not re-reviewed. List P3 findings for the user to decide; do not auto-fix them.
6. **Repeated failure.** When the same failure happens a second time, run `/paseo-committee` instead of letting the implementer retry in place.
7. **Resume.** On every "continue" or after a restart, list the agents still running first, then check `git log` and `git status` in each worktree.

## Waiting

Wait on `notifyOnFinish` notifications; no heartbeat by default. Only when this host can't be woken in the background (Codex, for example) set a fallback heartbeat of 50 minutes or more, and delete it when the task ends.

## Acceptance

Don't accept an agent's summary on its own word. For exploration and research, check sources, whether the evidence supports the conclusions, the acceptance checks and open questions. For implementation, check that the commits exist, the acceptance checks pass, the test log exits 0, and the diff matches the brief. Clean up the worktrees this task created. Report to the user the actual changes or findings, deviations, and anything left unverified.

When the roster sets `compare: true`, also follow the comparison log rule in [roster resolution](references/roster.md).

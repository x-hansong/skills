# Brief rules

The orchestrator reads this before writing any brief. A brief is the only context an agent starts with, so it holds what the agent needs and points to documents for the rest.

## Contents

A brief contains only: goal, done-condition, full baseline SHA (when a repo is involved), the notes path, the decided design, and the project rules to follow. Point to documents instead of restating them.

## Baseline

Run `git fetch` first, then read every SHA and branch fact in a brief from an explicit ref such as `git rev-parse origin/<branch>`. `HEAD` is whatever branch the checkout happens to sit on, possibly someone else's, and a local branch can trail its remote.

A baseline goes stale while a task runs. Before starting a build, install, upgrade, publish or push, `git fetch` again. When `origin/<branch>` is not an ancestor-or-equal of the candidate, integrate it first and say so in the brief.

## The decided design

For implementation, the design names, before the worker writes any logic:

- the file paths;
- the data shape and its organizing structure (a state machine over scattered flags, a table over branching, a typed model over repeated shape assumptions);
- the key trade-offs already made;
- the boundary rules: what may be written, validation, error handling.

Read the design principles copy in the notes before writing it, and name in the brief each principle that shaped it. The worker follows the design; to change it, the worker reports back first.

## Pre-flight

Pre-flight the brief before sending it. A read-only verifier does the checks, not you (see [when the reviewer runs](reviewer-use.md)): give it the literal values and the assumptions to test, and the rule to report evidence per item and change nothing. You read its table and cite it in the brief; you do not open source or query data yourself to do this.

- **Contract.** Beside every literal value the design fixes (an ID or version format, an enum, a time field), the verifier cites the validating type or rule as `file:line`. It runs each assumption about the input data (every record has field X, no item is empty) as one query over the real data and returns the query with its output. A value or assumption without that evidence goes back to exploration.
- **Integration.** When acceptance checks a commit with `git merge-base --is-ancestor`, the brief integrates by merge, which keeps that commit; rebase and squash rewrite it.
- **Tools.** For every CLI command the brief prescribes, the verifier runs the tool's version and `--help` for that exact subcommand where the worker will run, and reports whether each subcommand and flag in the brief is accepted. A command a user pasted from their own machine counts too: it may assume a newer tool version or a permission this account lacks. In one run, a subcommand that did not exist and a flag the installed version rejected each cost a full worker round.

## What the agent delivers

Require the agent to:

- for exploration and research: change no project files and create no worktree or commit; deliver facts: sources or file locations, what was searched, the evidence behind each conclusion and open questions, separating fact from inference. You write the design from those facts, so the deliverable lists no recommended design, proposed shape or suggested plan; a brief whose deliverable names such a section is a design hand-off, so drop the section and write that part yourself;
- for implementation: follow the test discipline copy in the notes within the test boundary the brief sets, commit step by step, run the relevant tests before each commit, and report done only when they all pass;
- report actual changes and deviations, not just a summary;
- deliver the report by pasting the block in [the deliverable clause](deliverable-clause.md) (copied into the notes by `init-notes.sh`) into the brief unchanged, replacing only the report name. Its rules: open every report with a verdict block of at most 15 lines (what was done or found, the evidence index, open questions, anything not verified). Keep the report itself under 8000 characters and put the detail in a file beside it named `<report>.detail.md`, with one `##` heading per claim the verdict block cites, so the orchestrator can `grep -n` that heading and read only that section. The orchestrator reads the report and opens the detail only where a claim is disputed. In a brief, state the 8000-character limit as characters, since agents miscount lines;
- write only inside the brief's **write scope**, stated as two positive lines: where the agent may write (a read-only agent still writes its report to the notes path), and what done leaves behind (commits with their SHAs in the report, or a file at a named path). For every repository the agent will write to, give its worktree's absolute path, including the orchestrator's workspace repository itself; main checkouts are read-only. Anything else in the brief that limits writes names its exact files;
- reply done only when that deliverable exists; an agent that hands work to its own subagents or background jobs waits for their terminal state first;
- append progress to `log.md` in the notes with `cat >> <notes>/log.md <<'EOF'` without re-reading the file; "only touch file X" in a brief never excludes the notes;
- start long jobs in the background with output written to a log, then repeatedly run `<this skill's dir>/scripts/wait-job.sh --log <log> --pid <pid>` in the same turn until it exits 0 (finished); 75 means still running, so call it again; 2 means fix the usage. For a completion check, use `-- <CHECK_CMD>...` instead of `--pid <pid>`; the command must exit 0 when finished, including a failed terminal job, whose result must then be read separately. Each wait defaults to 540 seconds, capped at 570, with a 60-second polling interval; `--max` and `--interval` take positive integer seconds. Every return prints the last five log lines when `--log` is given. Once the agent's turn ends, no background process or monitor wakes it again. Report back only when a decision is needed or the work is done; intermediate progress goes to the notes;
- for a long driver that runs many cases: check for a stop file between cases and exit cleanly when it appears. The brief names that file, and stopping the driver means creating it. Freezing or killing the driver's process voids the case in flight.

## Stop conditions

State five classes in the brief, so the agent routes them without asking each time:

| Situation | Handling |
| --- | --- |
| Network or transport error (stateless fetch failure, timeout) | Retry per the retry rule; stop when retries are exhausted |
| Business result (node failure, failed stats, PARTIAL) | Record the error code; exclude or continue per the agreed rule |
| Lint, format or type check fails on the agent's own change | Fix in place, then rerun the same check; stop and report only when the rerun still fails |
| Write request with uncertain outcome, or an uncovered protocol error | Reconcile read-only first, then stop and report |
| A long job that has already failed in a way it cannot recover from (a failed upload before its verification step, a stalled download), or one that is still running on a stale baseline | Stop waiting and report the evidence; do not let it run to a failure it will certainly reach. Do not signal or kill an external-service run (upload, publish, deploy) yourself unless the user has said you may: report first and ask. A killed run's exit file can read 0, so judge it by its log |

When a project skill already has an error-code table, cite it instead. Before a brief relies on a skill that performs writes, verify its request headers and required fields against the calling code; a new or changed write skill goes through the reviewer first (see [when the reviewer runs](reviewer-use.md)).

## Taking over and resuming

A fresh agent that takes over or follows up earlier work (a fix round, a retry, a changed scope) gets a consolidated brief: the original brief, every later directive, and the prior agent's report and branch. When the user changes the scope while an agent runs, tell that agent to stop or narrow to what still holds and commit it; give the new scope to a fresh agent instead of chaining instructions onto the old one, which silently drops directives.

An agent that stopped on a stop condition its brief named resumes in place when the scope is unchanged and the blocker was cleared outside it (the user granted a permission, a tool was upgraded, a missing input arrived): send it one message saying what changed and that the brief still holds. It keeps its context and its evidence, and no directive is chained, so no consolidated brief is needed. A changed scope or a new directive still goes to a fresh agent.

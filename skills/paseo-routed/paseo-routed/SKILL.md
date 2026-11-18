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
| This session (orchestrator) | Designs the plan: goal, boundaries, architecture, trade-offs, acceptance criteria. Splits work, writes briefs, dispatches, checks that deliverables exist and commands pass, wraps up. | Explore, research or implement the task itself, hand design to another agent, or open source files, upstream code or large diffs to check a brief or verify work (see the pre-flight in step 4 and [Acceptance](#acceptance)). |
| `worker` | Read-only exploration, web research, implementation, merging, review fixes. | Review its own work. |
| `reviewer` | Read-only review, claim verification and hard diagnosis, `paseo-committee`. | Write project files. |

Which Paseo profile plays each role comes from the roster. See [roster resolution](references/roster.md). Never fall back to this host's built-in subagents. If the roster or a profile can't be resolved, stop and tell the user.

## Steps

1. **Resolve the roster.** Follow [roster resolution](references/roster.md): read `~/.paseo-routed/config.yaml`, pick the roster (`--roster <name>` or the user naming one in the request, else `default_roster`), look up both profiles with `list_profiles`. Load the `paseo` skill for tool usage and [Paseo access](references/paseo-access.md) for how to expand a profile into `create_agent` settings.
2. **Scope.** In your first reply, tell the user in your own words the goal, the problem it solves and the smallest change you expect to meet it, then carry on without waiting; if the evidence rules out what the user asked for, show it and stop. Restate the scope and a **checkable done-condition** in two or three sentences, and write them to a shared notes directory outside the repo: `<notes_dir>/<topic>/`. Record the resolved roster and profile names there, and copy [test discipline](references/tests.md), [review method](references/review.md) and [design principles](references/principles.md) into the same directory. Ask the user only when the scope is too vague to write a done-condition. Run `<this skill's dir>/scripts/init-notes.sh --roster <name> --worker "<profile (provider/model)>" --reviewer "<profile (provider/model)>" <notes_dir>/<topic>`. It creates `scope.md`, `progress.md`, `log.md` and the three method copies, and refuses to overwrite notes that already exist. Then fill in `scope.md`: start it with one keyword line naming the features, samples, modules and repositories the task touches, so a later search by any of them finds this directory. Name in the done-condition the surface the user checks (a command or page in the main checkout), not an agent's report. Fill in `progress.md` as the resume point (see [Notes](#notes)).
   At any later fork, first ask whether running something would answer it (behaviour, output, layout, timing, whether a check separates); if so, dispatch a worker to try it and let the result decide. Ask the user only for a product or preference call no experiment settles. Otherwise proceed on a sensible default, and say which one and what the user could tell you to do instead.
3. **Split into work units**, each with a goal, acceptance checks and a file scope.
   - Several similar units: take the first through brief, implementation, review and acceptance before dispatching the rest, so a flaw in the brief costs one agent, not all of them.
   - When the code or docs need to be understood first, or the web searched, dispatch the worker for read-only exploration or research, then split the implementation from its evidence. A pure research task is accepted on its deliverable.
   - One unit, or units touching the same files: one worker does them serially.
   - Independent units with disjoint files: one worker per unit, each in its own worktree and branch. A separate worker merges and re-runs the relevant tests; no conflicts is not the same as verified.
4. **Brief.** A brief contains only: goal, done-condition, full baseline SHA (when a repo is involved), shared notes path, the decided design, and the project rules to follow. Point to documents instead of restating them. Run `git fetch` first, then read every SHA and branch fact in a brief from an explicit ref such as `git rev-parse origin/<branch>`; `HEAD` is whatever branch the checkout happens to sit on, possibly someone else's, and a local branch can trail its remote. A baseline goes stale while a task runs: before starting a build, install, upgrade, publish or push, `git fetch` again, and if `origin/<branch>` is not an ancestor-or-equal of the candidate, integrate it first and say so in the brief. For implementation, the decided design names, before the worker writes any logic: the file paths, the data shape and its organizing structure (a state machine over scattered flags, a table over branching, a typed model over repeated shape assumptions), the key trade-offs already made, and the boundary rules (what may be written, validation, error handling). Read the design principles copy in the notes before writing it, and name in the brief each principle that shaped it. The worker follows the design; to change it, the worker reports back first.

   Pre-flight the brief before sending it. A read-only verifier on the reviewer profile does the checks, not you: give it the literal values and the assumptions to test, and the rule to report evidence per item and change nothing. You read its table and cite it in the brief; you do not open source or query data yourself to do this.
   - **Contract.** Beside every literal value the design fixes (an ID or version format, an enum, a time field), the verifier cites the validating type or rule as `file:line`. It runs each assumption about the input data (every record has field X, no item is empty) as one query over the real data and returns the query with its output. A value or assumption without that evidence goes back to exploration.
   - **Integration.** When acceptance checks a commit with `git merge-base --is-ancestor`, the brief integrates by merge, which keeps that commit; rebase and squash rewrite it.

   Require the agent to:
   - for exploration and research: change no project files and create no worktree or commit; deliver facts: sources or file locations, what was searched, the evidence behind each conclusion and open questions, separating fact from inference. You write the design from those facts, so the deliverable lists no recommended design, proposed shape or suggested plan; a brief whose deliverable names such a section is a design hand-off, so drop the section and write that part yourself;
   - for implementation: follow the test discipline copy in the notes within the test boundary the brief sets, commit step by step, run the relevant tests before each commit, and report done only when they all pass;
   - report actual changes and deviations, not just a summary;
   - open every report with a verdict block of at most 15 lines (what was done or found, the evidence index, open questions, anything not verified) and put detail below it or in an appendix file; the orchestrator reads the verdict block and drills into the detail only where a claim is disputed;
   - write only inside the brief's **write scope**, stated as two positive lines: where the agent may write (a read-only agent still writes its report to the notes path), and what done leaves behind (commits with their SHAs in the report, or a file at a named path). For every repository the agent will write to, give its worktree's absolute path, including the orchestrator's workspace repository itself; main checkouts are read-only. Anything else in the brief that limits writes names its exact files;
   - reply done only when that deliverable exists; an agent that hands work to its own subagents or background jobs waits for their terminal state first;
   - append progress to `log.md` in the shared notes with `cat >> <notes>/log.md <<'EOF'` without re-reading the file; "only touch file X" in a brief never excludes the shared notes;
   - start long jobs in the background with output written to a log, then repeatedly run `<this skill's dir>/scripts/wait-job.sh --log <log> --pid <pid>` in the same turn until it exits 0 (finished); 75 means still running, so call it again; 2 means fix the usage. For a completion check, use `-- <CHECK_CMD>...` instead of `--pid <pid>`; the command must exit 0 when finished, including a failed terminal job, whose result must then be read separately. Each wait defaults to 540 seconds, capped at 570, with a 60-second polling interval; `--max` and `--interval` take positive integer seconds. Every return prints the last five log lines when `--log` is given. Once the turn ends, no background process or monitor wakes the agent again. Message back only when a decision is needed or the work is done; intermediate progress goes to the notes. A long driver that runs many cases checks for a stop file between cases and exits cleanly when it appears; the brief names that file, and stopping the driver means creating it. Do not stop the driver by freezing or killing its process (`SIGSTOP`, `SIGKILL`): in one run a `SIGSTOP` on the driver ended in exit 147 and its child processes were cleaned up, which voided the case in flight.

   A fresh agent that takes over or follows up earlier work (a fix round, a retry, a changed scope) gets a consolidated brief: the original brief, every later directive, and the prior agent's report and branch. When the user changes the scope while an agent runs, tell that agent to stop or narrow to what still holds and commit it; give the new scope to a fresh agent instead of chaining instructions onto the old one, which silently drops directives.

   State four classes of stop condition in the brief, so the agent routes them without asking each time:

   | Situation | Handling |
   | --- | --- |
   | Network or transport error (stateless fetch failure, timeout) | Retry per the retry rule; stop when retries are exhausted |
   | Business result (node failure, failed stats, PARTIAL) | Record the error code; exclude or continue per the agreed rule |
   | Lint, format or type check fails on the agent's own change | Fix in place, then rerun the same check; stop and report only when the rerun still fails |
   | Write request with uncertain outcome, or an uncovered protocol error | Reconcile read-only first, then stop and report |
   | A long job that has already failed in a way it cannot recover from (a failed upload before its verification step, a stalled download), or one that is still running on a stale baseline | Stop waiting and report the evidence; do not let it run to a failure it will certainly reach. Do not signal or kill an external-service run (upload, publish, deploy) yourself unless the user has said you may: report first and ask. A killed run's exit file can read 0, so judge it by its log |

   When a project skill already has an error-code table, cite it instead. Before a brief relies on a skill that performs writes, verify its request headers and required fields against the calling code; a new or changed write skill is reviewed by the reviewer before a worker runs it.
5. **Review.** After implementation, run a read-only review: `/paseo-advisor --profile <reviewer profile>` with a brief that points to the review method and design principles copies in the notes and gives the baseline SHA, the candidate, the Spec source and the project's standards files. Exploration and research are checked by this session against their evidence and are not auto-reviewed; call the reviewer for them only for a targeted review, hard diagnosis, or when the user asks. Author and reviewer are never the same agent. Before acting on a P0–P2 behaviour or Spec finding, rerun its command yourself: keep it only when the output shows the failure, otherwise move it to the user list with the output you got. Hand the kept P0–P2 findings to a **fresh** worker; the fix is done when the same commands print the required output. Extras added because they might help, and changes motivated by a hypothesis the evidence refuted, are reverted, not shipped. Every commit to be delivered needs a review verdict, except a commit whose diff touches only Markdown documentation and no code, config or test file, and fits on one screen: it may be delivered without a new verdict when the orchestrator has read that diff in full and the report names it. After fixes, merge conflict resolutions or any other commit since the last review, send the reviewer the diff from the last reviewed SHA to the new HEAD before delivery. Record each repository's reviewed SHA in [Notes](#notes); delivery is allowed only when it equals the HEAD to be pushed. List P3 and Unproven findings for the user to decide; do not auto-fix them.
6. **Retry and repeated failure.** Retry a failed agent by cause: a smaller scope after a context or memory limit, the same brief after a dropped connection, and after a tool error, check the profile's settings once, then stop and tell the user; never substitute another profile. When the same failure happens a second time, or two retries didn't help, don't let the implementer retry in place. Write down the premise the failed attempts share, then run `/paseo-committee` with that premise and the failure evidence, asking it to test the premise directly before proposing another fix.
7. **Resume.** On every "continue" or after a restart, read `progress.md`, list the agents still running, then check `git log` and `git status` in each worktree. The notes and git history are authoritative: don't redo verified work, but re-verify on the real artifact any inherited claim the next step relies on.

## Notes

`progress.md` is the resume point and yours alone; agents append to `log.md` beside it. Rewrite it at every unit boundary and keep it under 40 lines. Change one section at a time with `<this skill's dir>/scripts/set-progress.sh <notes_dir>/<topic> --append|--replace "<section>" <line>...` (lines come from standard input when none are given) instead of rewriting the file in a shell script; it refuses a result over 40 lines. It holds:

- intent, current step, what is verified, next steps, key files and gotchas;
- **decisions**, each tagged with its decision-maker: user (with the original message's timestamp) or orchestrator. Briefs and reports cite each decision with that tag, and the report lists orchestrator decisions (such as keeping existing failing tests) for the user to confirm;
- **live resources**: the full ID of every agent and workspace this task creates, recorded at creation, with the workspace's isolation (`worktree` or `local`). When one is done or archived, move its line to `log.md`;
- **reviewed SHA** per repository (step 5);
- **open gates**: a project delivery gate a brief deferred (a review page, a sync, a publish step) stays listed until it is met; report it as not verified if the task ends first.

## Waiting

Wait on `notifyOnFinish` notifications; no heartbeat by default. Only when this host can't be woken in the background (Codex, for example) set a fallback heartbeat of 50 minutes or more, and delete it when the task ends.

## Acceptance

Don't accept an agent's summary on its own word, and don't verify by reading source yourself. On every finish notification:

- Check that the brief's deliverable exists: the commits with their SHAs, or the file at the named path. When it doesn't, the agent is still working, whatever its reply says.
- Rerun the commands the brief names, and read the files the agent produced: the test log's exit code, the receipt, the report. Read a diff only through `--stat` against the brief's file scope. Read a diff in full only when it fits on one screen.
- Send every other check to a read-only verifier: a fresh agent on the reviewer profile, given the claims to test, the commands to run, the artifact paths, and the rule to report evidence per claim and change nothing. The verifier may read source; you read its report and the evidence it quotes. Check that the verifier's worktree shows no changes, as the roster rule requires.
- When the deliverable is a set of judgments (scores, verdicts, labels, classifications), a summary count is inconclusive on its own. Read the per-item output yourself (it is an artifact, not source): for every item whose judgment changed against the baseline or disagrees with a reference label, read the stated reason and the material it cites. A reason that contradicts its own verdict, or cites material outside the judged input, is a finding. When the project keeps a labelled reference set, compare against it and read only the disagreements.

For exploration and research, the verifier checks sources, whether the evidence supports the conclusions, the acceptance checks and open questions. For implementation, it checks that the diff matches the brief and that the acceptance checks hold on the committed head. Send back work that drifts past the brief: keep only what blocks this task and record the rest in the notes as follow-ups. Apply step 5's reviewed-SHA gate. Archive only the agents and workspaces listed under live resources in `progress.md`. A workspace is archived only when it is a `worktree` this task created and not this session's own workspace; archiving a workspace removes its directory. For a `local` workspace (one that adopts an existing directory such as a main checkout), or when ownership is uncertain, archive its agents and leave the workspace. Clean up the worktrees this task created. Before removing one, list what `git status --ignored` shows there that this task produced (run outputs, baselines, private data) and copy it before removal: outputs a tool in the main checkout reads (run and trial artifacts) go to the same relative path in the main checkout without overwriting, and that tool must then list them; private baselines and logs go to the notes directory. Removing a worktree deletes its ignored files too.

Before reporting, move every conclusion this run gave the user in answer to a question (why a limit exists, what was measured and what was not) into a document the project's entry file already routes to: a short statement beside the thing it explains, and the evidence in the project's verification records. Notes outside the repository are not where the next agent looks. When the repository keeps no such place, say so in the report instead of leaving the conclusion only in the notes.

Give every acceptance check one verdict: **verified** (you saw the evidence on the real artifact), **not verified** (the evidence shows it fails) or **inconclusive** (no evidence, or evidence from the wrong surface). Inconclusive is not a pass. Every count you report (verdicts, cases, files) comes from a script run over the deliverables, and counts identities, not directories or files: a re-scored or copied artifact of a run is that same run, so deduplicate by the original run ID; a retry is a new run. Never sum agent reports by hand.

When the roster sets `compare: true`, also follow the comparison log rule in [roster resolution](references/roster.md).

## Report

- Open with the user's goal in one sentence, then the actual changes or findings, deviations, and every check that isn't verified.
- Label each claim in the same sentence: measured (you ran or read it this session), inferred, or a guess. Never hand the user a check you could have run.
- State the scope a conclusion covers. A fix verified on one route, caller, file type or sample is reported as that, not as "fixed"; list the sibling routes or callers you did not check.
- Before sending a brief, report or any file text, check that it holds no U+FFFD (the replacement character, a sign the text was corrupted upstream). `grep -P '\xef\xbf\xbd'` misses it under a UTF-8 locale; use `grep -P '\x{FFFD}'` or count it in Python after decoding. Rewrite from the intended meaning; never ship the garbled text.
- Name each design principle that shaped a decision and the choice it changed; cite only principles read this run.
- Refer to an agent by the title Paseo shows for it, never by a letter or a nickname you coined, and give an internal term (a brief name, a matrix, a gate) a half-sentence of explanation the first time it appears in a message to the user. The user reads the Paseo list, not your notes.
- Account for every agent this run started: done, replaced, or absorbed into another agent's scope.
- Link only to files, commits and URLs this run produced or read.

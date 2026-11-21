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
| This session (orchestrator) | Designs the plan: goal, boundaries, architecture, trade-offs, acceptance criteria. Splits work, writes briefs, dispatches, checks that deliverables exist and commands pass, wraps up. | Explore, research or implement the task itself, hand design to another agent, or open source files, upstream code or large diffs to check a brief or verify work (see [acceptance](references/acceptance.md)). |
| `worker` | Read-only exploration, web research, implementation, merging, review fixes. | Review its own work. |
| `reviewer` | Read-only review, claim verification and hard diagnosis, `paseo-committee`. | Write project files. |

Read a reference when the step that names it comes up, not before. The reviewer runs only in the cases listed in [when the reviewer runs](references/reviewer-use.md); read it the first time you consider calling the reviewer. Which Paseo profile plays each role comes from the roster. See [roster resolution](references/roster.md). Never fall back to this host's built-in subagents. If the roster or a profile can't be resolved, stop and tell the user.

## Steps

1. **Resolve the roster.** Follow [roster resolution](references/roster.md): read `~/.paseo-routed/config.yaml`, pick the roster (`--roster <name>` or the user naming one in the request, else `default_roster`), look up both profiles with `list_profiles`. Load the `paseo` skill for tool usage and [Paseo access](references/paseo-access.md) for how to expand a profile into `create_agent` settings.
2. **Scope.** In your first reply, tell the user in your own words the goal, the problem it solves and the smallest change you expect to meet it, then carry on without waiting; if the evidence rules out what the user asked for, show it and stop. Restate the scope and a **checkable done-condition** in two or three sentences, and write them to a shared notes directory outside the repo: `<notes_dir>/<topic>/`. Record the resolved roster and profile names there. Ask the user only when the scope is too vague to write a done-condition. Run `<this skill's dir>/scripts/init-notes.sh --roster <name> --worker "<profile (provider/model)>" --reviewer "<profile (provider/model)>" <notes_dir>/<topic>`. It creates `scope.md`, `progress.md`, `log.md` and copies of `tests.md` (test discipline), `review.md` (review method), `principles.md` (design principles) and `deliverable-clause.md` (the report clause to paste into briefs), and refuses to overwrite notes that already exist. Don't read `tests.md` or `review.md`: workers and the reviewer follow the copies in the notes. Briefs that ask for a report paste `deliverable-clause.md` unchanged. Then fill in `scope.md`: start it with one keyword line naming the features, samples, modules and repositories the task touches, so a later search by any of them finds this directory. Name in the done-condition the surface the user checks (a command or page in the main checkout), not an agent's report. Fill in `progress.md` as the resume point (see [Notes](#notes)).
   At any later fork, first ask whether running something would answer it (behaviour, output, layout, timing, whether a check separates); if so, dispatch a worker to try it and let the result decide. Ask the user only for a product or preference call no experiment settles. Otherwise proceed on a sensible default, and say which one and what the user could tell you to do instead.
3. **Split into work units**, each with a goal, acceptance checks and a file scope.
   - Several similar units: take the first through brief, implementation, review and acceptance before dispatching the rest, so a flaw in the brief costs one agent, not all of them.
   - When the code or docs need to be understood first, or the web searched, dispatch the worker for read-only exploration or research, then split the implementation from its evidence. A pure research task is accepted on its deliverable.
   - One unit, or units touching the same files: one worker does them serially.
   - Independent units with disjoint files: one worker per unit, each in its own worktree and branch. A separate worker merges and re-runs the relevant tests; no conflicts is not the same as verified.
4. **Brief.** Before writing any brief, read [brief rules](references/brief.md): contents, baseline refresh, the decided design, the pre-flight, what the agent delivers (including the verdict block, write scope and `wait-job.sh`), the stop-condition table, and taking over or resuming an agent. When the brief carries a decided design, also read the [design principles](references/principles.md) (the copy in the notes). A brief names the notes path, the roster's profile for the agent, and, for each repository the agent writes to, that worktree's absolute path.
5. **Review.** After implementation, run a read-only review: `/paseo-advisor --profile <reviewer profile>` with a brief that points to the review method and design principles copies in the notes and gives the baseline SHA, the candidate, the Spec source and the project's standards files. Every other case that calls the reviewer is in [when the reviewer runs](references/reviewer-use.md). Author and reviewer are never the same agent. Before acting on a P0–P2 behaviour or Spec finding, rerun its command yourself: keep it only when the output shows the failure, otherwise move it to the user list with the output you got. Hand the kept P0–P2 findings to a **fresh** worker; the fix is done when the same commands print the required output. Extras added because they might help, and changes motivated by a hypothesis the evidence refuted, are reverted, not shipped. Every commit to be delivered needs a review verdict, except a commit whose diff touches only Markdown documentation and no code, config or test file, and fits on one screen: it may be delivered without a new verdict when the orchestrator has read that diff in full and the report names it. After fixes, merge conflict resolutions or any other commit since the last review, send the reviewer the diff from the last reviewed SHA to the new HEAD before delivery. Record each repository's reviewed SHA in [Notes](#notes); delivery is allowed only when it equals the HEAD to be pushed. List P3 and Unproven findings for the user to decide; do not auto-fix them. When two review rounds in a row return findings that the previous round's fix caused or that mirror it (a new check that rejects what the old one accepted, a patch whose own edge case is the next finding), stop patching: write the shared cause down and decide at design level, either accept the behaviour and document it, or redesign the part that keeps producing findings. A third round of the same kind is not review progress.
6. **Retry and repeated failure.** Retry a failed agent by cause: a smaller scope after a context or memory limit, the same brief after a dropped connection, and after a tool error, check the profile's settings once, then stop and tell the user; never substitute another profile. When the same failure happens a second time, or two retries didn't help, don't let the implementer retry in place. Write down the premise the failed attempts share, then run `/paseo-committee` with that premise and the failure evidence, asking it to test the premise directly before proposing another fix. Count the stops: the third time the run stops on the same step or the same gate, whatever the cause each time, ask whether the gate itself is right (does it test the user's actual requirement, can it be met at all, does it block something the user has said not to block), and put that question to `/paseo-committee` together with the gate's definition. Either fix the gate with the user's agreement or ask the user to relax it; do not build a fourth workaround around it. Record each stop as a line in `progress.md` under Open gates (`<gate> | stop <n> | <cause>`) so the count survives a compaction.
7. **Resume.** On every "continue" or after a restart, read `progress.md`, run `scripts/live-agents.sh` to see which listed agents still run, then check `git log` and `git status` in each worktree. After a context compaction, read [compaction](references/compaction.md) first. The notes and git history are authoritative: don't redo verified work, but re-verify on the real artifact any inherited claim the next step relies on.

## Notes

`progress.md` is the resume point and yours alone; agents append to `log.md` beside it. Rewrite it at every unit boundary and keep it under 40 lines. Change one section at a time with `<this skill's dir>/scripts/set-progress.sh <notes_dir>/<topic> --append|--replace "<section>" <line>...` (lines come from standard input when none are given) instead of rewriting the file in a shell script; it refuses a result over 40 lines. It holds:

- intent, current step, what is verified, next steps, key files and gotchas;
- **decisions**, each tagged with its decision-maker: user (with the original message's timestamp) or orchestrator. Briefs and reports cite each decision with that tag, and the report lists orchestrator decisions (such as keeping existing failing tests) for the user to confirm;
- **live resources**: the full ID of every agent and workspace this task creates, recorded at creation, with the workspace's isolation (`worktree` or `local`). When one is done or archived, move its line to `log.md`;
- **reviewed SHA** per repository (step 5);
- **open gates**: a project delivery gate a brief deferred (a review page, a sync, a publish step) stays listed until it is met; report it as not verified if the task ends first.

## Waiting

Wait on `notifyOnFinish` notifications; no heartbeat by default. A notification that arrives while you are mid-turn can go unanswered, so reconcile with `<this skill's dir>/scripts/live-agents.sh <notes_dir>/<topic>` at the start of every turn and before telling the user an agent is still running; [completion](references/paseo-access.md#completion) says how to read it. Only when this host can't be woken in the background (Codex, for example) set a fallback heartbeat of 50 minutes or more, and delete it when the task ends.

## Acceptance

Read [acceptance](references/acceptance.md) when the first agent finishes and apply it on every finish notification; it holds the checks, the cleanup of worktrees, the verdicts and the rule for counts. Apply step 5's reviewed-SHA gate.

Archive only the agents and workspaces listed under live resources in `progress.md`. A workspace is archived only when it is a `worktree` this task created and not this session's own workspace; archiving a workspace removes its directory. For a `local` workspace (one that adopts an existing directory such as a main checkout), or when ownership is uncertain, archive its agents and leave the workspace.

When the roster sets `compare: true`, also follow the comparison log rule in [roster resolution](references/roster.md).

## Report

When wrapping up, read and follow [report](references/report.md). Refer to an agent by the title Paseo shows for it.

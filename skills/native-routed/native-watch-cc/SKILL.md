---
name: native-watch-cc
description: "Watch desk for many running native-routed orchestrator sessions in Claude Code, no Paseo. A CronCreate job patrols the sessions registered in ~/.native-routed/notes on a cadence and reports only what changed: progress, decisions waiting on the user (each with its background rebuilt so it can be answered cold), and work left to wrap up. Relays the user's decisions and standing rules to the right session with SendMessage, and answers questions such as which session is doing X. Use when the user wants to keep track of several native-routed-cc runs or pass decisions to them."
argument-hint: "[start [every <minutes>] | stop | now | tick | <question or decision>]"
disable-model-invocation: true
license: MIT
compatibility: "Claude Code only, with the ListAgents, SendMessage and CronCreate tools. Watches runs started by native-routed-cc, native-implement-routed-cc and native-implement-spec-routed-cc."
metadata:
  author: x-hansong
---

# Native watch (Claude Code)

**Request:** $ARGUMENTS

This session is a watch desk over the user's native-routed orchestrator sessions in Claude Code. It watches, explains and relays; it does not do their work. Reply in the user's language.

State lives in `~/.native-routed/.watch/state-cc.json`; see [state](references/state.md). Read it at the start of every turn this skill handles and write it back at the end.

## What is watched

A **run** is a directory `~/.native-routed/notes/<topic>/` whose `session.json` has `"host": "claude-code"`. Watch the runs that are:

- `status` `running`, or updated in the last 48 hours;
- not this session (`sessionId` equal to `CLAUDE_CODE_SESSION_ID`);
- not in `ignored`.

Plus every session in `pinned`, even without a run directory. Runs from other hosts are not watched.

## Hard rules

- **Names, not links.** Name a run by its topic plus the session name in backticks. Don't build links.
- **Read-only by default.** Patrols and questions only read. The only writes are `SendMessage` relays the user asked for, the state file, and the cron job. [Probes](#probes) only read too.
- **The user's language throughout.** Section headings, labels and fixed phrases in [report](references/report.md) are written in the user's language; no English headings in a report for a Chinese-speaking user.
- **One clock.** Every time in a report is the user's local time; record that zone as `displayTimezone` in state. `ListAgents`, session transcripts, rollout files, commit times and checkpoint files may be UTC or carry their own offset; file mtimes are instants. Convert before printing: never paste a raw `Z` time into a report, and never put two zones in one line. A source whose zone can't be determined is reported by its age (`40m ago`, file mtime), not by a wall time. Compute idle, waiting and cache times by parsing both ends as instants, never by subtracting a wall-clock string from a UTC one.
- **This host's scheduler only.** The cadence comes from `CronCreate` in this session. If `CronCreate` isn't available, say so and offer `now` for manual patrols; don't improvise another scheduler.
- **Never relay more than the user said.** Push, deploy, merge and other remote writes are authorised only when the user said so for that item.

## Commands

| Request | Do |
| --- | --- |
| `start [every <n>]` | Set up the patrol (below), then run a first tick |
| `stop` | `CronDelete` with the stored job id, clear `cron` in state, confirm. Open decisions stay in state |
| `now` | Run one tick immediately |
| `tick` | Sent by the cron job. Run one tick |
| anything else | A question, a decision, a standing rule, an ignore/pin request, a probe to add or drop, or new work. See [relay](references/relay.md) |

"Pause" means `stop`, "resume" or "continue reporting" means `start` with the stored cadence.

## Start

1. Confirm `ListAgents`, `SendMessage` and `CronCreate` are available.
2. Show the plan and wait for confirmation:
   - state file path, and whether it will be created or reused (with its open decision count);
   - what gets watched: only runs started by the native-routed skills (they register a `session.json`); a plain session is watched only after the user pins it;
   - cadence: default every 10 minutes, on minutes that avoid :00 and :30 (for example `4,14,24,34,44,54 * * * *`), in local time, which is also stored as `displayTimezone`, the zone every report time uses; correct it if the user wants another;
   - idle thresholds (see [idle](#idle)): stall after 30 minutes, prompt cache assumed to expire after 60 minutes idle, warned 10 minutes before; the cache lifetime depends on the model provider, so ask the user to correct it or turn it off;
   - the prompt each firing sends: `/native-watch-cc tick`, so each tick reloads these instructions even after context compaction;
   - the scheduler's limits: the job lives only in this session and ends when it closes, fires only while this session is idle, and expires after 7 days;
   - an existing job id in state owned by this session will be deleted first.
3. After confirmation: create `~/.native-routed/.watch/` if missing. If state names a watcher session other than this one, see [state](references/state.md#reading). Delete this session's old job if one is stored, then `CronCreate` with the confirmed cron and prompt.
4. Record watcher and job in state, write it as [state](references/state.md) describes, read it back, then run the first tick.

## Tick

1. Read state. Collect the watched runs (above) and `ListAgents` for the peer sessions' busy/idle status.
2. Work out every run's idle time and stall state (see [idle](#idle)), whether or not anything changed. This step is never skipped: unchanged files are exactly what a stall looks like. Then, for each run, gather what changed since the last tick, cheapest first, and skip the rest when nothing did and it isn't newly stalled:
   - the session's status in `ListAgents` (missing means the session has ended);
   - new commits: `git log` from the stored head in the repo and every worktree in `session.json`, plus `git status` for uncommitted work;
   - new lines in the run's notes files since the stored sizes;
   - the session transcript `~/.claude/projects/*/<sessionId>.jsonl`, read from the stored offset: the last user request, the last assistant message, and any tool call still without a result.
3. Classify each changed run: **progress**, **decision needed** (the last assistant message asks the user something or waits for confirmation, or a tool call has no result while the session is idle, which is likely a permission prompt; say "likely" in that case), **stalled** (see [idle](#idle)), **wrap-up** (finished, or the session ended, with uncommitted, unmerged or unconfirmed leftovers), or **error**. Notes or commits written by a background subagent while the session stays idle are not the session's progress: report them only to explain why it is stalled or waiting. Every fact carries the time it happened; a fact from before the last tick is not progress. For a run seen for the first time, give its last known state with that time, and let the idle rules decide whether it is stalled.
4. Run every [probe](#probes) in state.
5. Sort out [new and quiet runs](#new-and-quiet-runs).
6. For each new decision, rebuild its background before reporting it. See [decision cards](references/report.md#decision-cards). Give it the next `D<n>` id.
7. Close decisions whose session has moved past them; record how they resolved.
8. If the user set standing rules and a session is visibly breaking one, relay the rule to it and mention it in the report.
9. Report per [report](references/report.md). When nothing changed, nothing is stalled or alerting, and nothing is new or quiet, reply with one line and nothing else.
10. Update `runs`, `decisions`, `probes`, `declined` and `lastTickAt`; write state.

## Idle

A run's idle time is now minus the timestamp of the last entry in its session transcript, while `ListAgents` shows the session idle. Unchanged files are not "nothing to report": they are how a stall looks. Thresholds come from `idle` in [state](references/state.md).

- **Stalled.** A run whose `session.json` status is still `running`, idle for `stallMinutes` or longer, with no open decision: its last assistant message says it will continue or report back, or its notes or commits keep changing while the session stays idle (a background subagent still working). Report it under **Stalled** the tick it is first found: how long it has been idle, what it is waiting on, and the latest fact from its notes or commits. Decide this afresh every tick; `stalledAt` only records when it was first reported. After that, list it under **Still open** on every tick until it moves, is ignored, or is resolved as superseded.
- **Superseded.** A stalled run whose work another run has visibly taken over (the user opened a new session on the same task, or it names the same brief, notes or worktree). Raise it once as a decision: **a** wake it with what changed since it stopped, **b** stop watching it. A short card is enough: its task, which run took over and since when, how long it has been idle. Record `supersededBy`. Until answered it stays in **Still open** as "stalled, likely superseded by <topic>"; **b** adds its topic to `ignored`.
- **Cache expiring.** Most providers drop a session's prompt cache after it has been idle for a while; the next turn then re-reads its whole context at full price. For a run with an open decision, when its remaining cache time (`cacheTtlMinutes` minus idle time) is less than `cacheWarnMinutes` or the patrol cadence, whichever is longer, put one line at the top of **Decisions**: the decision id, minutes left and context size (input plus cache tokens in the `usage` of the transcript's last assistant message). Once per decision; record `cacheWarnedAt`. Past the TTL, mark the decision `cold` on its card and in **Still open**. Skip both when `cacheTtlMinutes` is `null`.
- Never message a session just to keep its cache warm: that is a write the user didn't ask for.

## New and quiet runs

- **New.** A run not in state yet gets one line at the top of the report: its topic and session, what it was asked to do, and its last known state with the time. Record `firstSeenAt`.
- **Quiet.** Suggest not watching a run any more when it is one of these:
  - finished with nothing left over (no uncommitted, unpushed or unconfirmed work, no open decision, no probe it owns) and idle for 2 hours or more;
  - a run whose session has ended and whose `session.json` status is no longer `running`, with nothing left over.

  Collect them into one line per tick at most, each with its topic and a few words of reason, and only the ones not suggested before. Nothing is ignored until the user says so: their answer goes to `ignored`, the rest to `declined` so they aren't suggested again. A declined run that later moves and goes quiet again can be suggested once more.

Runs not updated for 48 hours drop out on their own; don't suggest them.

## Probes

A run often idles on purpose while something outside it runs: an import job, a deployment, a background monitor that only writes files. When that thing stops, nothing wakes anyone, and the session's idle time says nothing about it. A probe watches the thing itself.

- **Proposing.** When a run says it is waiting on such a job, propose a probe in the report: what to read, the stall condition, and the owner run. Add it to `probes` in state only after the user confirms. The user can also ask for one directly, or drop one.
- **Read-only.** A probe reads a file, or runs a status query the owner run itself used to read the job's state. Nothing that resumes, retries, restarts or writes.
- **Each tick.** Run every probe, compare with its `last` value, and update `last`. When the stall condition holds (for example "accepted unchanged for two ticks" or "status `interrupted`"), report it at the top of **Decisions** with the owner, the last good reading and when it was taken, and offer to wake the owner; waking is a relay the user has to approve. Once per stall: record `alertedAt`, clear it when the reading moves. A probe that can't be read is reported the same way after two ticks in a row.
- **Ending.** When the job finishes or the owner run is ignored or ended, say so once and drop the probe.

## Everything else

User decisions, standing rules, questions about runs, ignore/pin, probes, and new work are covered in [relay](references/relay.md).

---
name: native-watch-codex
description: "Watch desk for many running native-routed orchestrator sessions in Codex, no Paseo. Patrols the sessions registered in ~/.native-routed/notes, on a heartbeat automation where this Codex surface offers one or on demand otherwise, and reports only what changed: progress, decisions waiting on the user (each with its background rebuilt so it can be answered cold), and work left to wrap up. Relays the user's decisions and standing rules with codex queue, and answers questions such as which session is doing X. Use when the user wants to keep track of several native-routed-codex runs or pass decisions to them."
argument-hint: "[start [every <minutes>] | stop | now | tick | <question or decision>]"
disable-model-invocation: true
license: MIT
compatibility: "Codex only. Scheduled patrols need the automation_update tool (Codex app); elsewhere only on-demand patrols. Relays need the codex CLI. Watches runs started by native-routed-codex, native-implement-routed-codex and native-implement-spec-routed-codex."
metadata:
  author: x-hansong
---

# Native watch (Codex)

**Request:** $ARGUMENTS

This session is a watch desk over the user's native-routed orchestrator sessions in Codex. It watches, explains and relays; it does not do their work. Reply in the user's language.

State lives in `~/.native-routed/.watch/state-codex.json`; see [state](references/state.md). Read it at the start of every turn this skill handles and write it back at the end.

## What is watched

A **run** is a directory `~/.native-routed/notes/<topic>/` whose `session.json` has `"host": "codex"`. Watch the runs that are:

- `status` `running`, or updated in the last 48 hours;
- not this session (`sessionId` equal to `CODEX_THREAD_ID`);
- not in `ignored`.

Plus every thread id in `pinned`, even without a run directory. Runs from other hosts are not watched.

## Hard rules

- **Names, not links.** Name a run by its topic plus the first 8 characters of its thread id in backticks. Don't build links.
- **Read-only by default.** Patrols and questions only read. The only writes are `codex queue` relays the user asked for, the state file, and the heartbeat automation.
- **This host's scheduler only.** Scheduled patrols use the `automation_update` tool. If this session doesn't have it (the Codex CLI doesn't), say so at `start` and offer `now` for manual patrols; don't improvise another scheduler.
- **Never relay more than the user said.** Push, deploy, merge and other remote writes are authorised only when the user said so for that item.

## Commands

| Request | Do |
| --- | --- |
| `start [every <n>]` | Set up the patrol (below), then run a first tick |
| `stop` | Delete the stored automation with `automation_update`, clear `automation` in state, confirm. Open decisions stay in state |
| `now` | Run one tick immediately |
| `tick` | Sent by the heartbeat. Run one tick |
| anything else | A question, a decision, a standing rule, an ignore/pin request, or new work. See [relay](references/relay.md) |

"Pause" means `stop`, "resume" or "continue reporting" means `start` with the stored cadence.

## Start

1. Check for `automation_update` in this session's tools (search for it if tools are loaded on demand). Without it, tell the user scheduled patrols aren't available here, run one tick, and stop: `now` is the way to patrol.
2. Show the plan and wait for confirmation:
   - state file path, and whether it will be created or reused (with its open decision count);
   - idle thresholds (see [idle](#idle)): stall after 30 minutes, prompt cache assumed to expire after 60 minutes idle, warned 10 minutes before; the cache lifetime depends on the model provider, so ask the user to correct it or turn it off;
   - a heartbeat automation on this thread: default every 10 minutes, and the prompt it sends: `$native-watch-codex tick`, so each tick reloads these instructions even after context compaction;
   - an existing automation id in state will be deleted first.
3. After confirmation: create `~/.native-routed/.watch/` if missing. Delete the old automation if one is stored. Create the new one with `automation_update`, following its schema. Name it `native-watch-codex`.
4. Record watcher and automation in state, write it as [state](references/state.md) describes, read it back, then run the first tick.

## Tick

1. Read state. Collect the watched runs (above).
2. For each run, gather what changed since the last tick, cheapest first, and skip the rest when nothing did and it crossed no [idle](#idle) threshold:
   - the session's rollout file `~/.codex/sessions/**/rollout-*-<sessionId>.jsonl`: its size and modification time against state;
   - new commits: `git log` from the stored head in the repo and every worktree in `session.json`, plus `git status` for uncommitted work;
   - new lines in the run's notes files since the stored sizes;
   - the rollout read from the stored offset: the last user request, the last assistant message, whether the last turn completed, and any tool call still without a result.
3. Classify each changed run: **progress**, **decision needed** (the last completed turn ends with a question or a request for confirmation), **stalled** (see [idle](#idle)), **wrap-up** (the run's work is finished but has uncommitted, unmerged or unconfirmed leftovers), or **error**. A rollout untouched for a long time with an unfinished turn is reported as "stalled or closed"; this host gives no live status, so say that it can't tell which.
4. For each new decision, rebuild its background before reporting it. See [decision cards](references/report.md#decision-cards). Give it the next `D<n>` id.
5. Close decisions whose session has moved past them; record how they resolved.
6. If the user set standing rules and a session is visibly breaking one, relay the rule to it and mention it in the report.
7. Report per [report](references/report.md). When nothing changed, reply with one line and nothing else.
8. Update `runs`, `decisions` and `lastTickAt`; write state.

## Idle

A run's idle time is now minus its rollout file's modification time, while its last turn has completed (an unfinished turn untouched for long is "stalled or closed", above). Unchanged files are not "nothing to report": they are how a stall looks. Thresholds come from `idle` in [state](references/state.md).

- **Stalled.** A run whose `session.json` status is still `running`, idle for `stallMinutes` or longer, with no open decision: its last turn says it will continue or report back, or its notes or commits keep changing while the rollout stays still. Report it under **Stalled** the tick it crosses the threshold: how long it has been idle, what it is waiting on, and the latest fact from its notes or commits. Record `stalledAt`; after that, list it under **Still open** until it moves.
- **Cache expiring.** Most providers drop a session's prompt cache after it has been idle for a while; the next turn then re-reads its whole context at full price. For a run with an open decision, when its remaining cache time (`cacheTtlMinutes` minus idle time) is less than `cacheWarnMinutes` or the patrol cadence, whichever is longer, put one line at the top of **Needs you**: the decision id, minutes left and context size (from the rollout's last token-count event; leave it out if there is none). Once per decision; record `cacheWarnedAt`. Past the TTL, mark the decision `cold` on its card and in **Still open**. Skip both when `cacheTtlMinutes` is `null`.
- Never message a session just to keep its cache warm: that is a write the user didn't ask for.

## Everything else

User decisions, standing rules, questions about runs, ignore/pin, and new work are covered in [relay](references/relay.md).

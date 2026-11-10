---
name: paseo-watch
description: "Watch desk for many running Paseo orchestrator agents. A Paseo heartbeat patrols the top-level orchestrators on a cadence and reports only what changed: progress, decisions waiting on the user (each with its background rebuilt so it can be answered cold), and work left to wrap up. Relays the user's decisions and standing rules back to the right agents, and answers questions such as which session is doing X or what an agent did today. Use when the user wants to keep track of several Paseo agents, be reminded of their progress, or pass decisions to them."
argument-hint: "[start [every <minutes>] | stop | now | tick | <question or decision>]"
disable-model-invocation: true
license: MIT
compatibility: "Claude Code or Codex running as a Paseo agent (PASEO_AGENT_ID set) with Paseo MCP tools. Uses the paseo skill for tool details and paseo-routed for new work."
metadata:
  author: x-hansong
---

# Paseo watch

**Request:** $ARGUMENTS

This session is a watch desk over the user's Paseo orchestrator agents. It watches, explains and relays; it does not do their work. Reply in the user's language.

State lives in `~/.paseo-routed/.watch/state.json`; see [state](references/state.md). Read it at the start of every turn this skill handles and write it back at the end.

## Hard rules

- **IDs, not links.** Name agents by their 7-character short id in backticks plus a short title. Don't build `paseo://` or web links.
- **Orchestrators only.** Watch top-level agents: no `paseo.parent-agent-id` label, not archived, not this session (`$PASEO_AGENT_ID`), not in `ignored`. Look at children only to explain a parent's state.
- **Read-only by default.** Patrols and questions only read. The only writes are `send_agent_prompt` for relays the user asked for, the state file, and the heartbeat. [Probes](#probes) only read too.
- **The user's language throughout.** Section headings, labels and fixed phrases in [report](references/report.md) are written in the user's language; no English headings in a report for a Chinese-speaking user.
- **One clock.** Every time in a report is the user's local time; record that zone as `displayTimezone` in state. Paseo tool times (`updatedAt`, activity, status) are ISO-8601 UTC, and times read from files, checkpoints and logs may be UTC, local, or unlabelled. Convert before printing: never paste a raw `Z` time into a report, and never put two zones in one line. A source whose zone can't be determined is reported by its age (`40m ago`, file mtime), not by a wall time. Compute idle, waiting and cache times by parsing both ends as instants, never by subtracting a wall-clock string from a UTC one.
- **No fallback scheduler.** The cadence comes from a Paseo heartbeat. If `PASEO_AGENT_ID` is unset or `create_heartbeat` is unavailable, stop and say this session isn't a Paseo agent; don't use the host's cron or loop instead.
- **Never relay more than the user said.** Push, deploy, merge and other remote writes are authorised only when the user said so for that item.

## Commands

| Request | Do |
| --- | --- |
| `start [every <n>]` | Set up the patrol (below), then run a first tick |
| `stop` | `delete_heartbeat` with the stored id, clear `heartbeat` in state, confirm. Open decisions stay in state |
| `now` | Run one tick immediately |
| `tick` | Sent by the heartbeat. Run one tick |
| anything else | A question, a decision, a standing rule, an ignore/pin request, a probe to add or drop, or new work. See [relay](references/relay.md) |

"Pause" means `stop`, "resume" or "continue reporting" means `start` with the stored cadence: heartbeats have no pause.

## Start

1. Confirm `PASEO_AGENT_ID` is set and Paseo MCP tools are present. Load the `paseo` skill for tool details.
2. Show the plan and wait for confirmation:
   - state file path, and whether it will be created or reused (with its open decision count);
   - heartbeat: cadence (default every 10 minutes; `*/<n> * * * *`), the host's time zone (also stored as `displayTimezone`, the zone every report time uses; correct it if the user wants another), and the prompt it sends;
   - idle thresholds (see [idle](#idle)): stall after 30 minutes, prompt cache assumed to expire after 60 minutes idle, warned 10 minutes before; the cache lifetime depends on the model provider, so ask the user to correct it or turn it off;
   - an existing heartbeat id in state will be deleted first.
3. After confirmation: create `~/.paseo-routed/.watch/` if missing. Delete the old heartbeat if one is stored; if deletion fails because another agent owns it, stop and tell the user which watcher holds it. Call `create_heartbeat` with `name: "paseo-watch"` and as prompt the invocation of this skill with `tick` in the host's syntax (`/paseo-watch tick` in Claude Code, `$paseo-watch tick` in Codex), so each tick reloads these instructions even after context compaction.
4. Record watcher and heartbeat in state, write it as [state](references/state.md) describes, read it back, then run the first tick.

## Tick

1. Read state. `list_agents` with statuses `running`, `idle`, `error`, `initializing`, `sinceHours: 48`, `limit: 100`; add hosts listed in state.
2. Keep orchestrators (hard rules), plus any `pinned` id. From the same list, note each orchestrator's children (agents whose `paseo.parent-agent-id` label is its id).
3. Work out every orchestrator's idle time and stall state from this tick's list (see [idle](#idle)), whether or not anything changed. This step is never skipped: an unchanged agent is exactly what a stall looks like.
4. Read `get_agent_activity` (start with `limit: 8`) and `get_agent_status` (pending permissions, `requiresAttention`, context size in `lastUsage.contextWindowUsedTokens`) for each orchestrator that is new, whose `status` or `updatedAt` differs from state, whose children's `status` or `updatedAt` differ from `children` in state, or that is stalled and not yet reported.
5. Classify each one read: **progress**, **decision needed** (it asked the user something, a permission is pending, or it stopped to wait for confirmation), **stalled** (see [idle](#idle)), **wrap-up** (finished but has uncommitted, unpushed or unconfirmed leftovers), or **error**. A child's progress is never the parent's progress: report it only to explain why the parent is stalled or waiting. Every fact carries the time it happened; a fact from before the last tick is not progress. For an agent seen for the first time, give its last known state with that time, and let the idle rules decide whether it is stalled.
6. Run every [probe](#probes) in state.
7. Sort out [new and quiet orchestrators](#new-and-quiet-orchestrators).
8. For each new decision, rebuild its background before reporting it. See [decision cards](references/report.md#decision-cards). Give it the next `D<n>` id.
9. Close decisions whose agent has moved past them; record how they resolved.
10. If the user set standing rules and an agent is visibly breaking one (for example running a full test suite against a "related tests only" rule), relay the rule to it and mention it in the report.
11. Report per [report](references/report.md). When nothing changed, nothing is stalled or alerting, and nothing is new or quiet, reply with one line and nothing else.
12. Update `agents`, `decisions`, `probes`, `declined` and `lastTickAt`; write state.

A completion notification from an agent this session prompted is a one-agent tick: steps 3 to 12 for that agent.

## Idle

An agent's idle time is now minus its `updatedAt` while its status is `idle`. An unchanged `updatedAt` is not "nothing to report": it is how a stall looks. Thresholds come from `idle` in [state](references/state.md).

- **Stalled.** An orchestrator idle for `stallMinutes` or longer that has no open decision and isn't finished: its last message says it will continue or report back, or a child is still running, or a child changed after the parent last did. Decide this afresh every tick from `list_agents`; `stalledAt` only records when it was first reported. Report it under **Stalled** the tick it is first found: how long it has been idle, what it is waiting on, and its children's latest fact. After that, list it under **Still open** on every tick until it moves, is ignored, or is resolved as superseded.
- **Missed wake-up.** A child finished a turn more than 5 minutes after its parent's last turn, and the parent is still idle: the parent was supposed to wake on that and didn't. Report it as stalled that tick, without waiting for `stallMinutes`.
- **Superseded.** A stalled orchestrator whose work another orchestrator has visibly taken over (the user opened a new session on the same task, it names the same brief or notes directory, or it now drives the same children or jobs). Raise it once as a decision: **a** wake it with what changed since it stopped, **b** stop watching it. A short card is enough: its task, who took over and since when, how long it has been idle. Record `supersededBy`. Until answered it stays in **Still open** as "stalled, likely superseded by `<id>`"; **b** adds it to `ignored`.
- **Cache expiring.** Most providers drop an agent's prompt cache after it has been idle for a while; the next turn then re-reads its whole context at full price. For an agent with an open decision, when its remaining cache time (`cacheTtlMinutes` minus idle time) is less than `cacheWarnMinutes` or the patrol cadence, whichever is longer, put one line at the top of **Decisions**: the decision id, minutes left and context size. Once per decision; record `cacheWarnedAt`. Past the TTL, mark the decision `cold` on its card and in **Still open**. Skip both when `cacheTtlMinutes` is `null`.
- Never ping an agent just to keep its cache warm: that is a write the user didn't ask for.

## New and quiet orchestrators

- **New.** An orchestrator not in state yet gets one line at the top of the report: its short id and title, what it was asked to do, and its last known state with the time. Record `firstSeenAt`.
- **Quiet.** Suggest not watching an orchestrator any more when it is one of these:
  - finished with nothing left over (no uncommitted, unpushed or unconfirmed work, no open decision, no probe it owns) and idle for 2 hours or more;
  - a one-off question: no children, no commits, and its last message is an answer rather than a promise to continue;
  - another watch desk (a session running this skill).

  Collect them into one line per tick at most, each with its id and a few words of reason, and only the ones not suggested before. Nothing is ignored until the user says so: their answer goes to `ignored`, the rest to `declined` so they aren't suggested again. A declined orchestrator that later moves and goes quiet again can be suggested once more.

Archived agents and agents older than 48 hours drop out on their own; don't suggest them.

## Probes

An agent often idles on purpose while something outside Paseo runs: an import job, a deployment, a background monitor that only writes files. When that thing stops, nothing wakes anyone, and the agent's idle time says nothing about it. A probe watches the thing itself.

- **Proposing.** When an agent says it is waiting on such a job, propose a probe in the report: what to read, the stall condition, and the owner agent. Add it to `probes` in state only after the user confirms. The user can also ask for one directly, or drop one.
- **Read-only.** A probe reads a file, or runs a status query the owner agent itself used to read the job's state. Nothing that resumes, retries, restarts or writes.
- **Each tick.** Run every probe, compare with its `last` value, and update `last`. When the stall condition holds (for example "accepted unchanged for two ticks" or "status `interrupted`"), report it at the top of **Decisions** with the owner, the last good reading and when it was taken, and offer to wake the owner; waking is a relay the user has to approve. Once per stall: record `alertedAt`, clear it when the reading moves. A probe that can't be read is reported the same way after two ticks in a row.
- **Ending.** When the job finishes or the owner is ignored or archived, say so once and drop the probe.

## Everything else

User decisions, standing rules, questions about agents, ignore/pin, probes, and new work are covered in [relay](references/relay.md).

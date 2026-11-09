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
- **Read-only by default.** Patrols and questions only read. The only writes are `send_agent_prompt` for relays the user asked for, the state file, and the heartbeat.
- **No fallback scheduler.** The cadence comes from a Paseo heartbeat. If `PASEO_AGENT_ID` is unset or `create_heartbeat` is unavailable, stop and say this session isn't a Paseo agent; don't use the host's cron or loop instead.
- **Never relay more than the user said.** Push, deploy, merge and other remote writes are authorised only when the user said so for that item.

## Commands

| Request | Do |
| --- | --- |
| `start [every <n>]` | Set up the patrol (below), then run a first tick |
| `stop` | `delete_heartbeat` with the stored id, clear `heartbeat` in state, confirm. Open decisions stay in state |
| `now` | Run one tick immediately |
| `tick` | Sent by the heartbeat. Run one tick |
| anything else | A question, a decision, a standing rule, an ignore/pin request, or new work. See [relay](references/relay.md) |

"Pause" means `stop`, "resume" or "continue reporting" means `start` with the stored cadence: heartbeats have no pause.

## Start

1. Confirm `PASEO_AGENT_ID` is set and Paseo MCP tools are present. Load the `paseo` skill for tool details.
2. Show the plan and wait for confirmation:
   - state file path, and whether it will be created or reused (with its open decision count);
   - heartbeat: cadence (default every 10 minutes; `*/<n> * * * *`), the host's time zone, and the prompt it sends;
   - idle thresholds (see [idle](#idle)): stall after 30 minutes, prompt cache assumed to expire after 60 minutes idle, warned 10 minutes before; the cache lifetime depends on the model provider, so ask the user to correct it or turn it off;
   - an existing heartbeat id in state will be deleted first.
3. After confirmation: create `~/.paseo-routed/.watch/` if missing. Delete the old heartbeat if one is stored; if deletion fails because another agent owns it, stop and tell the user which watcher holds it. Call `create_heartbeat` with `name: "paseo-watch"` and as prompt the invocation of this skill with `tick` in the host's syntax (`/paseo-watch tick` in Claude Code, `$paseo-watch tick` in Codex), so each tick reloads these instructions even after context compaction.
4. Record watcher and heartbeat in state, write it as [state](references/state.md) describes, read it back, then run the first tick.

## Tick

1. Read state. `list_agents` with statuses `running`, `idle`, `error`, `initializing`, `sinceHours: 48`, `limit: 100`; add hosts listed in state.
2. Keep orchestrators (hard rules), plus any `pinned` id. From the same list, note each orchestrator's children (agents whose `paseo.parent-agent-id` label is its id).
3. Skip an agent whose `status` and `updatedAt` match state, unless one of its children's `status` or `updatedAt` differs from `children` in state, or it crossed an [idle](#idle) threshold since the last tick. For each new or changed one, read `get_agent_activity` (start with `limit: 8`) and `get_agent_status` (pending permissions, `requiresAttention`, context size in `lastUsage.contextWindowUsedTokens`).
4. Classify each changed agent: **progress**, **decision needed** (it asked the user something, a permission is pending, or it stopped to wait for confirmation), **stalled** (see [idle](#idle)), **wrap-up** (finished but has uncommitted, unpushed or unconfirmed leftovers), or **error**. A child's progress is never the parent's progress: report it only to explain why the parent is stalled or waiting.
5. For each new decision, rebuild its background before reporting it. See [decision cards](references/report.md#decision-cards). Give it the next `D<n>` id.
6. Close decisions whose agent has moved past them; record how they resolved.
7. If the user set standing rules and an agent is visibly breaking one (for example running a full test suite against a "related tests only" rule), relay the rule to it and mention it in the report.
8. Report per [report](references/report.md). When nothing changed, reply with one line and nothing else.
9. Update `agents`, `decisions` and `lastTickAt`; write state.

A completion notification from an agent this session prompted is a one-agent tick: steps 3 to 9 for that agent.

## Idle

An agent's idle time is now minus its `updatedAt` while its status is `idle`. An unchanged `updatedAt` is not "nothing to report": it is how a stall looks. Thresholds come from `idle` in [state](references/state.md).

- **Stalled.** An orchestrator idle for `stallMinutes` or longer that has no open decision and isn't finished: its last message says it will continue or report back, or a child is still running, or a child changed after the parent last did. Report it under **Stalled** the tick it crosses the threshold: how long it has been idle, what it is waiting on, and its children's latest fact. Record `stalledAt`; after that, list it under **Still open** until it moves.
- **Cache expiring.** Most providers drop an agent's prompt cache after it has been idle for a while; the next turn then re-reads its whole context at full price. For an agent with an open decision, when its remaining cache time (`cacheTtlMinutes` minus idle time) is less than `cacheWarnMinutes` or the patrol cadence, whichever is longer, put one line at the top of **Needs you**: the decision id, minutes left and context size. Once per decision; record `cacheWarnedAt`. Past the TTL, mark the decision `cold` on its card and in **Still open**. Skip both when `cacheTtlMinutes` is `null`.
- Never ping an agent just to keep its cache warm: that is a write the user didn't ask for.

## Everything else

User decisions, standing rules, questions about agents, ignore/pin, and new work are covered in [relay](references/relay.md).

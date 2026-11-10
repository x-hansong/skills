# State

`~/.paseo-routed/.watch/state.json` lets a tick compare against the last one and keeps decisions and rules across context compaction and new sessions. It is the only file this skill writes.

## Shape

```json
{
  "version": 1,
  "watcher": { "agentId": "<this session's PASEO_AGENT_ID>", "serverId": null },
  "heartbeat": { "id": "<heartbeat id>", "cron": "*/10 * * * *", "timezone": "<IANA zone>", "createdAt": "<ISO time>" },
  "hosts": [],
  "lastTickAt": "<ISO time>",
  "displayTimezone": "<IANA zone: the user's local zone>",
  "idle": { "stallMinutes": 30, "cacheTtlMinutes": 60, "cacheWarnMinutes": 10 },
  "agents": {
    "<full agent id>": {
      "shortId": "c8fa548",
      "title": "Delivery (L/M)",
      "status": "running",
      "updatedAt": "<ISO time from list_agents>",
      "contextTokens": 215000,
      "firstSeenAt": "<ISO time>",
      "stalledAt": null,
      "supersededBy": null,
      "children": { "<child agent id>": { "status": "running", "updatedAt": "<ISO time>" } },
      "summary": "<one line: last known state>"
    }
  },
  "decisions": [
    {
      "id": "D3",
      "agentId": "<full agent id>",
      "question": "<one line>",
      "background": { "task": "", "soFar": "", "stuckOn": "", "options": [{ "key": "a", "text": "", "recommended": true }], "ifNoAnswer": "" },
      "askedAt": "<ISO time>",
      "cacheWarnedAt": null,
      "status": "open",
      "resolution": null
    }
  ],
  "nextDecision": 4,
  "rules": [
    { "text": "Run only tests related to the change, then push and deploy to pre-release", "since": "<ISO time>" }
  ],
  "probes": [
    {
      "id": "P1",
      "name": "<what it watches, one line>",
      "owner": "<full agent id>",
      "read": "<file and field, or the read-only status query the owner used>",
      "stallWhen": "<condition, e.g. accepted unchanged for two ticks, or status interrupted>",
      "last": { "at": "<ISO time>", "value": "<short reading>", "ok": true },
      "unchangedTicks": 0,
      "unreadableTicks": 0,
      "alertedAt": null,
      "since": "<ISO time>"
    }
  ],
  "nextProbe": 2,
  "ignored": [],
  "declined": [],
  "pinned": []
}
```

- `idle` holds the [idle](../SKILL.md#idle) thresholds in minutes. A missing `idle` or missing key takes the defaults shown. `cacheTtlMinutes: null` turns cache warnings off; set it to the provider's cache lifetime otherwise.
- `agents[].stalledAt` is when the agent was first reported stalled; clear it when its `status` or `updatedAt` changes. It never decides whether an agent is stalled: each tick decides that afresh. `supersededBy` is the id of the orchestrator that took over its work, set when the superseded decision is raised. `contextTokens` is the last context size read from `get_agent_status`. `children` holds each child's last seen `status` and `updatedAt`, only for comparison.
- `displayTimezone` is the zone every reported time is shown in: the host's zone at `start`, corrected if the user says otherwise. `heartbeat.timezone` only says when the heartbeat fires and may differ. Store instants as ISO-8601 with an offset; a probe's raw reading may keep its source text, but the report converts it.
- `serverId` is `null` for the local daemon. `hosts` holds extra `serverId`s the user asked to watch.
- `decisions[].status` is `open`, `relayed` (the user answered, the answer was sent) or `closed` (the agent moved past it, with or without an answer). Drop closed decisions older than 7 days.
- `declined` holds ids the user chose to keep watching when they were suggested as quiet, each as `{ "id": "<id>", "at": "<ISO time>" }`; drop an entry when that orchestrator moves again. `firstSeenAt` is when this watch first saw the orchestrator.
- Decision ids never get reused: always take `nextDecision`. Probe ids likewise come from `nextProbe`.
- `probes` holds only probes the user confirmed. `last` is the latest reading; `ok: false` when it couldn't be read. `unchangedTicks` and `unreadableTicks` count consecutive ticks, for conditions such as "unchanged for two ticks". `alertedAt` is set when a stall is reported and cleared when the reading moves. A probe's `read` must not hold tokens or credentials; if the query needs them, name where the owner gets them instead.
- `agents` keeps only agents seen in the last 48 hours.

## Reading

- Missing file: start empty. Don't create it until a write is due.
- Unparseable file, or `version` other than `1`: stop and tell the user the path and the parse error. Don't overwrite it.
- `watcher.agentId` differs from `PASEO_AGENT_ID`: another session owns this watch. Say so and ask whether to take it over; taking over means deleting the old heartbeat (it may fail if the old agent owns it; then tell the user to stop it there) and creating a new one.

## Writing

Write the whole file to `state.json.tmp` in the same directory, then rename it over `state.json`. After `start`, read it back once and check it parses and holds the new heartbeat id.

Keep secrets out: no tokens, no environment values, no file contents beyond one-line summaries.

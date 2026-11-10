# State

`~/.native-routed/.watch/state-codex.json` lets a tick compare against the last one and keeps decisions and rules across context compaction and new sessions. It is the only file this skill writes.

## Shape

```json
{
  "version": 1,
  "watcher": { "sessionId": "<this session's CODEX_THREAD_ID>" },
  "automation": { "id": "<automation id>", "everyMinutes": 10, "createdAt": "<ISO time>" },
  "lastTickAt": "<ISO time>",
  "displayTimezone": "<IANA zone: the user's local zone>",
  "idle": { "stallMinutes": 30, "cacheTtlMinutes": 60, "cacheWarnMinutes": 10 },
  "runs": {
    "<topic>": {
      "sessionId": "<from session.json>",
      "rolloutPath": "<rollout file>",
      "rolloutSize": 56789,
      "rolloutMtime": "<ISO time>",
      "heads": { "<repo or worktree path>": "<SHA>" },
      "notesSizes": { "<notes file>": 1234 },
      "contextTokens": 215000,
      "firstSeenAt": "<ISO time>",
      "stalledAt": null,
      "supersededBy": null,
      "summary": "<one line: last known state>"
    }
  },
  "decisions": [
    {
      "id": "D3",
      "topic": "<topic>",
      "sessionId": "<thread id>",
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
      "owner": "<topic>",
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

- `ignored` holds topics; `pinned` holds thread ids.
- `decisions[].status` is `open`, `relayed` (the user answered, the answer was sent) or `closed` (the session moved past it, with or without an answer). Drop closed decisions older than 7 days.
- `idle` holds the [idle](../SKILL.md#idle) thresholds in minutes. A missing `idle` or missing key takes the defaults shown. `cacheTtlMinutes: null` turns cache warnings off; set it to the provider's cache lifetime otherwise.
- `displayTimezone` is the zone every reported time is shown in: the host's zone at `start`, corrected if the user says otherwise. The `automation` cadence only says when a tick fires and may differ. Store instants as ISO-8601 with an offset; a probe's raw reading may keep its source text, but the report converts it.
- `runs[].stalledAt` is when the run was first reported stalled; clear it when the session takes a new turn. It never decides whether a run is stalled: each tick decides that afresh. `supersededBy` is the topic of the run that took over its work, set when the superseded decision is raised. `contextTokens` is the last context size read.
- `declined` holds topics the user chose to keep watching when they were suggested as quiet, each as `{ "topic": "<topic>", "at": "<ISO time>" }`; drop an entry when that run moves again. `firstSeenAt` is when this watch first saw the run.
- Decision ids never get reused: always take `nextDecision`. Probe ids likewise come from `nextProbe`.
- `probes` holds only probes the user confirmed. `last` is the latest reading; `ok: false` when it couldn't be read. `unchangedTicks` and `unreadableTicks` count consecutive ticks, for conditions such as "unchanged for two ticks". `alertedAt` is set when a stall is reported and cleared when the reading moves. A probe's `read` must not hold tokens or credentials; if the query needs them, name where the owner gets them instead.
- `runs` keeps only runs seen in the last 48 hours.

## Reading

- Missing file: start empty. Don't create it until a write is due.
- Unparseable file, or `version` other than `1`: stop and tell the user the path and the parse error. Don't overwrite it.
- `watcher.sessionId` differs from this session's: another session was the watcher. Say so, and ask whether to take over; taking over means deleting its automation with `automation_update` (if this session can) and creating a new one for this thread.

## Writing

Write the whole file to `state-codex.json.tmp` in the same directory, then rename it over `state-codex.json`. After `start`, read it back once and check it parses and holds the new automation id.

Keep secrets out: no tokens, no environment values, no file contents beyond one-line summaries.

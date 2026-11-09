# State

`~/.native-routed/.watch/state-codex.json` lets a tick compare against the last one and keeps decisions and rules across context compaction and new sessions. It is the only file this skill writes.

## Shape

```json
{
  "version": 1,
  "watcher": { "sessionId": "<this session's CODEX_THREAD_ID>" },
  "automation": { "id": "<automation id>", "everyMinutes": 10, "createdAt": "<ISO time>" },
  "lastTickAt": "<ISO time>",
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
      "stalledAt": null,
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
  "ignored": [],
  "pinned": []
}
```

- `ignored` holds topics; `pinned` holds thread ids.
- `decisions[].status` is `open`, `relayed` (the user answered, the answer was sent) or `closed` (the session moved past it, with or without an answer). Drop closed decisions older than 7 days.
- `idle` holds the [idle](../SKILL.md#idle) thresholds in minutes. A missing `idle` or missing key takes the defaults shown. `cacheTtlMinutes: null` turns cache warnings off; set it to the provider's cache lifetime otherwise.
- `runs[].stalledAt` is when the run was first reported stalled; clear it when the session takes a new turn. `contextTokens` is the last context size read.
- Decision ids never get reused: always take `nextDecision`.
- `runs` keeps only runs seen in the last 48 hours.

## Reading

- Missing file: start empty. Don't create it until a write is due.
- Unparseable file, or `version` other than `1`: stop and tell the user the path and the parse error. Don't overwrite it.
- `watcher.sessionId` differs from this session's: another session was the watcher. Say so, and ask whether to take over; taking over means deleting its automation with `automation_update` (if this session can) and creating a new one for this thread.

## Writing

Write the whole file to `state-codex.json.tmp` in the same directory, then rename it over `state-codex.json`. After `start`, read it back once and check it parses and holds the new automation id.

Keep secrets out: no tokens, no environment values, no file contents beyond one-line summaries.

# State

`~/.native-routed/.watch/state-cc.json` lets a tick compare against the last one and keeps decisions and rules across context compaction and new sessions. It is the only file this skill writes.

## Shape

```json
{
  "version": 1,
  "watcher": { "sessionId": "<this session's CLAUDE_CODE_SESSION_ID>", "sessionName": "<name from ListAgents>" },
  "cron": { "id": "<CronCreate job id>", "expr": "4,14,24,34,44,54 * * * *", "createdAt": "<ISO time>" },
  "lastTickAt": "<ISO time>",
  "runs": {
    "<topic>": {
      "sessionId": "<from session.json>",
      "sessionName": "<from session.json>",
      "status": "busy",
      "heads": { "<repo or worktree path>": "<SHA>" },
      "notesSizes": { "<notes file>": 1234 },
      "transcriptOffset": 56789,
      "summary": "<one line: last known state>"
    }
  },
  "decisions": [
    {
      "id": "D3",
      "topic": "<topic>",
      "sessionName": "<session name>",
      "question": "<one line>",
      "background": { "task": "", "soFar": "", "stuckOn": "", "options": [{ "key": "a", "text": "", "recommended": true }], "ifNoAnswer": "" },
      "askedAt": "<ISO time>",
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

- `runs[].status` is the `ListAgents` status (`busy`, `idle`) or `ended` when the session is no longer listed.
- `ignored` holds topics; `pinned` holds session names.
- `decisions[].status` is `open`, `relayed` (the user answered, the answer was sent) or `closed` (the session moved past it, with or without an answer). Drop closed decisions older than 7 days.
- Decision ids never get reused: always take `nextDecision`.
- `runs` keeps only runs seen in the last 48 hours.

## Reading

- Missing file: start empty. Don't create it until a write is due.
- Unparseable file, or `version` other than `1`: stop and tell the user the path and the parse error. Don't overwrite it.
- `watcher.sessionId` differs from this session's: another session was the watcher. Its cron job lives only in that session, so this one can't delete it. Say so, and ask whether to take over; taking over means the user stops the old watch in that session (or closes it) and this session creates its own job.

## Writing

Write the whole file to `state-cc.json.tmp` in the same directory, then rename it over `state-cc.json`. After `start`, read it back once and check it parses and holds the new job id.

Keep secrets out: no tokens, no environment values, no file contents beyond one-line summaries.

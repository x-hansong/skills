# Relay and questions

Everything the user says to the watch desk that isn't `start`, `stop`, `now` or `tick`.

## Decisions

The user answers with an id (`D3 a`), quotes a card, or names a run ("tell the parser run to continue").

1. Match the answer to an open decision. If it could fit more than one, or a bare letter arrives with several decisions open, ask which one. Don't guess.
2. Re-check the session: its `ListAgents` status and the tail of its transcript. If it moved on since the card was written, tell the user what changed and confirm the answer still applies.
3. Send with `SendMessage` to the run's `sessionName`, using the template below. A run whose `sessionName` is `null`, or whose session has ended, can't be reached: say so and give the user the message to paste when they reopen it.
4. Mark the decision `relayed` with the user's answer as `resolution`. Tell the user in one or two lines what was sent and what will come back.

```text
User decision on your question "<question, one line>": <the answer, in the user's words where possible>.

Authorised: <exactly what the user allowed>.
Not authorised: <push / deploy / merge / remote writes / deleting files, whichever the answer didn't cover>; stop and report before any of these.
When done, report: <what you changed, commit SHAs, test commands with exit codes, anything left open>.
Standing rules: <the rules from state, one line each, or omit>.
```

On the next tick, check the session's reported result against what was authorised (commits exist, nothing remote was touched without leave).

## Standing rules

A rule is a "from now on" instruction for all orchestrators, e.g. "only run tests related to the change, then push and deploy to pre-release".

1. Restate it in one line and add it to `rules` in state.
2. Ask whether to send it to the running sessions now, unless the user already said to. Send it with the same template, opening with "Standing rule from the user, applies from now on:".
3. From then on, include rules in every relay, and on each tick relay a rule to a session that is visibly breaking it.

A rule that conflicts with a project's own rules (for example a repo that requires a full CI run before merging) is relayed with the conflict named, so the session can stop and ask instead of silently picking one.

## Questions about runs

"Which session is doing X", "what did the parser run do today, how long until done", "what is D3 about again".

- Answer from state first, then the runs' `scope.md` and notes, `git log`, and the transcripts. For "today" questions, read enough of the transcript and notes to cover the period.
- If no run matches, say so and name the closest ones; don't create one.
- ETAs come only from evidence: measured throughput, remaining units in a plan, a running job's progress. Otherwise say no estimate is possible and why.

## Ignore and pin

- "Stop watching `<topic>`": add to `ignored`. Its open decisions get `closed` with resolution `ignored by user`.
- "Also watch `<session name>`": add to `pinned`. A pinned session without a run directory is watched through `ListAgents` and its transcript only.

## New work

The watch desk doesn't do the work. For a new task, tell the user to start it in a new Claude Code session with `native-routed-cc`; the run registers itself and shows up on the next tick. For a one-line instruction to an existing session, relay it as a decision without an id.

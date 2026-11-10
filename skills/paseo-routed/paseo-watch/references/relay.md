# Relay and questions

Everything the user says to the watch desk that isn't `start`, `stop`, `now` or `tick`.

## Decisions

The user answers with an id (`D3 a`), quotes a card, or names an agent ("tell f4e22b1 to continue").

1. Match the answer to an open decision. If it could fit more than one, or a bare letter arrives with several decisions open, ask which one. Don't guess.
2. Re-check the agent with `get_agent_status` and the last few activity entries. If it moved on since the card was written, tell the user what changed and confirm the answer still applies.
3. Send with `send_agent_prompt`, `notifyOnFinish: true`. Use the template below.
4. Mark the decision `relayed` with the user's answer as `resolution`. Tell the user in one or two lines what was sent and what will come back.

```text
User decision on your question "<question, one line>": <the answer, in the user's words where possible>.

Authorised: <exactly what the user allowed>.
Not authorised: <push / deploy / merge / remote writes / deleting files, whichever the answer didn't cover>; stop and report before any of these.
When done, report: <what you changed, commit SHAs, test commands with exit codes, anything left open>.
Standing rules: <the rules from state, one line each, or omit>.
```

`activeTurnBehavior`: `steer` when the agent is running and the answer concerns its current work; otherwise leave the default.

When the completion notification arrives, check the reported result against what was authorised (commits exist, nothing remote was touched without leave), then report it as a one-agent tick.

## Standing rules

A rule is a "from now on" instruction for all orchestrators, e.g. "only run tests related to the change, then push and deploy to pre-release".

1. Restate it in one line and add it to `rules` in state.
2. Ask whether to send it to the running orchestrators now, unless the user already said to. Send it with the same template, opening with "Standing rule from the user, applies from now on:".
3. From then on, include rules in every relay, and on each tick relay a rule to an agent that is visibly breaking it.

A rule that conflicts with a project's own rules (for example a repo that requires a full CI run before merging) is relayed with the conflict named, so the agent can stop and ask instead of silently picking one.

## Questions about agents

"Which session is doing X", "what did `c8fa548` do today, how long until done", "what is D3 about again".

- Answer from state first, then `list_agents` (titles, labels) and `get_agent_activity`. For "today" questions, read enough activity to cover the period.
- Name sessions by short id and title. If no session matches, say so and name the closest ones; don't create one.
- ETAs come only from evidence: measured throughput, remaining units in a plan, a running job's progress. Otherwise say no estimate is possible and why.
- When the user's id looks wrong (a typo, the same id twice), say which agents you assumed.

## Ignore and pin

- "Stop watching `<id>`": add to `ignored`. Its open decisions get `closed` with resolution `ignored by user`.
- "Also watch `<id>`": add to `pinned`, even if it is a child agent.
- "Stop watching `<id>`" for the agent's probes too: drop the probes it owns, and say which.

## Quiet suggestions

The user answers a **Quiet** line with `all`, some of the ids, or "keep `<id>`".

- The chosen ones go to `ignored`, as with "stop watching"; the ones not chosen go to `declined`. Confirm in one line.
- An answer that leaves the line unaddressed (the user talks about something else) changes nothing; suggest them again next time one of them changes.

## Probes

- "Watch `<job>`" or a yes to a proposed probe: restate what will be read, the stall condition and the owner in one line, check that the read is read-only (see [probes](../SKILL.md#probes)), take one reading now, then add it with the next `P<n>` id.
- "Drop `P1`" or "stop watching `<job>`": remove it and confirm.
- "Wake the owner" after a probe alert: relay it like a decision. Give the probe's readings and times, and authorise only what the user said (for example "read-only diagnosis", or "resume once if the cause is a restart").

## New work

The watch desk doesn't do the work. For a new task ("start a worker to check the build queue"), load the `paseo-routed` skill and follow it, then pin the new orchestrator so the next tick reports on it. For a one-line instruction to an existing agent, relay it as a decision without an id.

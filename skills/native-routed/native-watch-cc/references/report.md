# Report

A tick report is short when little changed and complete when a decision is waiting. Write in the user's language.

## Layout

```markdown
**Patrol HH:MM** · <n> runs · <n> changed

### Needs you
`D2` cache expires in ~8m (<topic>, context 215k tokens): answering now avoids a full re-read
<decision cards, oldest first>

### Stalled
- <topic> `<session>`: idle 2h08m, said it would report when done; notes still growing, last fact: <fact>

### Progress
| Run | Session | Status | What changed since last patrol |
| --- | --- | --- | --- |

### Wrap-up
- <topic> `<session>`: <what is left and who has to act>

### Still open
D2 (<topic>, waiting 3h10m, cold), D5 (<topic>, waiting 40m) · stalled: <topic> (idle 2h08m)
```

- Drop empty sections.
- **Progress** lists only runs that changed since the last tick. One line each: the new fact (a commit, a test result, a deployment, a finding), not what the session is "working on".
- **Stalled** lists runs the tick they cross the stall threshold. One line each: idle time, what the session said it was waiting for, and what is still changing. Then they move to **Still open**.
- **Still open** lists earlier decisions that are still unanswered, one id each, with how long they have waited and `cold` once the cache has expired, then runs still stalled with their idle time. Don't repeat their cards; the user asks "D2?" to see one again.
- When nothing changed and nothing new is open: one line, e.g. `Patrol 14:20: no changes; D2, D5 still open.`
- Errors go under **Needs you** as a decision card when the session is stuck, otherwise under **Progress**.

## Decision cards

A decision can reach the user hours after the work that led to it. Each card has to be answerable with no memory of that work.

### Rebuilding the background

Before writing a card, work out from the run's own record, not from memory:

1. **The task.** The run's `scope.md` and the first user request in the session transcript, plus any brief it points to.
2. **The path here.** The last few milestones before the question: what was tried, what was found, what got merged or deployed.
3. **The blocker.** The concrete fact that forced the question: an error, a missing file, a rule that conflicts, two options with different costs.
4. **What each option does.** In consequences: what changes, what is touched (local only, remote branch, pre-release, production), what can be undone, what it costs in time.
5. **What happens if nobody answers.** Whether the session is idle, keeps going on a default, or holds something such as a lock or an unpushed branch.

Store the result in the decision's `background` field in state, so "D3?" later can be answered without reading the transcript again. If the record doesn't explain something, say so in the card instead of guessing.

### Card format

```markdown
**D3 · delivery-flow `<session>`** · asked 13:05, waiting 2h10m, cache cold

- **Task:** <one sentence: what the user originally asked this run to do and why>
- **So far:** <two or three facts that led here>
- **Stuck on:** <the blocker, in plain words; define any jargon, ticket or unit names>
- **Options:**
  - **a** <action> — <consequence; reversible?> ← recommended: <why>
  - **b** <action> — <consequence>
- **If no answer:** <what the session does meanwhile>

Reply `D3 a`, or say what you want instead.
```

- Expand every internal name the first time it appears in a card: a unit letter, a ticket code, a script name, an error code. "Unit M (the change that gives the backtest runner a dedicated config bundle)" rather than "unit M".
- Use the session's recommendation when it gave one, and say it is the session's. Add your own only when you have a reason, and give the reason.
- When one session asks several questions at once, give each its own id and card. Group them under one heading for that run.
- Add `cache cold` to the heading once the session's cache has expired, so the user knows answering costs a full re-read.
- Keep each card under about 12 lines. Link nothing; ids and file names in backticks are enough.

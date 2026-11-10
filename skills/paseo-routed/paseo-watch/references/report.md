# Report

A tick report is short when little changed and complete when a decision is waiting.

## Language

Write the whole report in the user's language, headings and labels included. The layout below names sections in English only so this file can refer to them; never print those English names to a user who writes in another language. For Chinese:

| Section | Heading |
| --- | --- |
| Patrol | 巡检 HH:MM（<zone>） · <n> 个编排者 · <n> 个有变化 |
| New | 新加入 |
| Quiet | 可以不再盯 |
| Decisions | 需要你决定 |
| Stalled | 停摆 |
| Progress | 进展 |
| Wrap-up | 待收尾 |
| Still open | 仍未解决 |

The same goes for card labels (任务、进展、卡在、选项、没人回时), `cold` (缓存已失效), "recommended" (推荐) and the one-line reply when nothing changed.

## Layout

```markdown
**<Patrol> HH:MM (<zone>)** · <n> orchestrators · <n> changed

<New>: `<id>` <name>, <what it was asked to do>; last known state at HH:MM: <fact>
<Quiet>: `<id>` (finished 15:10, nothing left over), `<id>` (one-off question) — reply with the ones to stop watching, or `all`

### <Decisions>
Probe `P1` stalled: <what it watches>, last good reading <value> at HH:MM (<n>m ago), owner `<id>`; wake the owner?
`D2` cache expires in ~8m (`<id>`, context 215k tokens): answering now avoids a full re-read
<decision cards, oldest first>

### <Stalled>
- `<id>` <name>: idle 2h08m since HH:MM, said it would report when done; worker `<child id>` still running, last fact at HH:MM: <fact>

### <Progress>
| ID | Name | Status | What changed since last patrol |
| --- | --- | --- | --- |
| `<id>` | <name> | idle | HH:MM <fact> |

### <Wrap-up>
- `<id>` <name>: <what is left and who has to act>

### <Still open>
D2 (`<id>`, waiting 3h10m, cold), D5 (`<id>`, waiting 40m) · stalled: `<id>` (idle 2h08m), `<id>` (idle 4h, likely superseded by `<id>`) · probes: `P1` ok at HH:MM
```

- Drop empty sections.
- **One clock.** Every HH:MM in the report is the user's local time, and the title names the zone once. Convert anything copied from a checkpoint, log, transcript or commit before printing; when quoting a source value, give its local equivalent (`11:31:45Z = 19:31`). If a source's zone is unknown, show its age instead (`40m ago`). Two zones never share a line.
- **New** and **Quiet** are one line each, right under the title, only on the tick they apply. See [new and quiet orchestrators](../SKILL.md#new-and-quiet-orchestrators).
- **Decisions** opens with probe alerts and cache warnings, one line each, then the cards.
- **Progress** lists only agents that changed since the last tick. One line each: the new fact (a commit, a test result, a deployment, a finding) with the time it happened, not what the agent is "working on". A fact from before the last tick is not progress.
- **Stalled** lists orchestrators the tick they are first found stalled. One line each: idle time and since when, what it said it was waiting for, and what its children are doing, with times. Then they move to **Still open**.
- **Still open** lists earlier decisions that are still unanswered, one id each, with how long they have waited and `cold` once the cache has expired, then every orchestrator still stalled with its idle time, recomputed this tick. Don't repeat their cards; the user asks "D2?" to see one again.
- When nothing changed, nothing is stalled and no probe alerts: one line, e.g. `Patrol 14:20 (<zone>): no changes; D2, D5 still open.` in the user's language.
- Errors go under **Decisions** as a decision card when the agent is stuck, otherwise under **Progress**.

## Decision cards

A decision can reach the user hours after the work that led to it. Each card has to be answerable with no memory of that work.

### Rebuilding the background

Before writing a card, work out from the agent's own record, not from memory:

1. **The task.** The agent's first user prompt (its title is usually a truncation of it) and any brief it points to. Read further back in `get_agent_activity` with a larger `limit` until the original request is found, or read the brief or notes file it names.
2. **The path here.** The last few milestones before the question: what was tried, what was found, what got merged or deployed.
3. **The blocker.** The concrete fact that forced the question: an error, a missing file, a rule that conflicts, two options with different costs.
4. **What each option does.** In consequences: what changes, what is touched (local only, remote branch, pre-release, production), what can be undone, what it costs in time.
5. **What happens if nobody answers.** Whether the agent is idle, keeps going on a default, or holds something such as a lock or an unpushed branch.

Store the result in the decision's `background` field in state, so "D3?" later can be answered without reading the activity again. If the record doesn't explain something, say so in the card instead of guessing.

### Card format

```markdown
**D3 · `c8fa548` Delivery (L/M)** · asked 13:05, waiting 2h10m, cache cold

- **Task:** <one sentence: what the user originally asked this agent to do and why>
- **So far:** <two or three facts that led here>
- **Stuck on:** <the blocker, in plain words; define any jargon, ticket or unit names>
- **Options:**
  - **a** <action> — <consequence; reversible?> ← recommended: <why>
  - **b** <action> — <consequence>
- **If no answer:** <what the agent does meanwhile>

Reply `D3 a`, or say what you want instead.
```

- Expand every internal name the first time it appears in a card: a unit letter, a ticket code, a script name, an error code. "Unit M (the change that gives the backtest runner a dedicated config bundle)" rather than "unit M".
- Use the agent's recommendation when it gave one, and say it is the agent's. Add your own only when you have a reason, and give the reason.
- When one agent asks several questions at once, give each its own id and card. Group them under one heading for that agent.
- Add `cache cold` to the heading once the agent's cache has expired, so the user knows answering costs a full re-read.
- Keep each card under about 12 lines. Link nothing; ids and file names in backticks are enough.

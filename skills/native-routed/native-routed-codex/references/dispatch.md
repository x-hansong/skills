# Dispatch and waiting

All agents are subagents started with `spawn_agent`. They see none of this conversation: everything they need is in the brief or in files the brief names.

## Starting a subagent

| Parameter | Value |
| --- | --- |
| `task_name` | Role and unit, e.g. `worker-unit-b` |
| `message` | The brief. Long briefs go to a file under the notes directory and the message points to it |
| `model`, `reasoning_effort` | The role's resolved values; omit a value the config leaves out |
| `fork_turns` | Always `"none"`. The default copies this whole conversation into the agent, which defeats a clean brief |

Subagents can start subagents of their own. Every brief forbids it: all dispatching stays in this session.

## Worktrees

`spawn_agent` has no isolation option; this session creates the worktree before dispatch:

```bash
git worktree add -b <branch> <path> <full baseline SHA>
```

- Follow the project's worktree conventions (`AGENTS.md`, `CLAUDE.md`) when it has them. Otherwise use `~/.native-routed/worktrees/<topic>/<unit>` and a branch named `<topic>/<unit>`.
- If the project needs setup steps in a new worktree (install, registration, restore), run them on create and on resume.
- The brief names the absolute worktree path and says to run every command there and touch nothing outside it except the notes.
- Record each worktree in `session.json` before dispatching to it.
- Remove a worktree with `git worktree remove <path>`, then delete `~/.native-routed/worktrees/<topic>/` once it is empty.

## Waiting

This session isn't woken in the background, so it waits actively: call `wait_agent` with a long timeout (up to 3,600,000 ms) and repeat until every agent it waits on has finished. On each timeout, read the notes for progress and tell the user in one line what is still running. Don't describe a result before the agent returns it.

## Follow-ups and stopping

- `followup_task` sends a message and starts a turn: use it for clarifying questions and missing information.
- `send_message` queues a message without starting a turn.
- `interrupt_agent` stops a runaway turn.

Review fixes always go to a fresh worker, never back to the author.

## Read-only agents

Reviewers, researchers and committee members get a brief that says read-only: no edits, no commits, no branch switches, no worktrees. To review a branch, they read it through git (`git diff <baseline>..<branch>`, `git show`) instead of checking it out. After each one finishes, run `git status` in every tree it could reach; any change is a finding to report, and is undone only with the user's agreement.

## Passing methods

Subagents get the test discipline and the review method as files: the copies in `~/.native-routed/notes/<topic>/`, passed by path. Never point a subagent at a skill's install path, and never ask it to load a skill the user has to run by hand.

The review method reports two axes, Standards and Spec. Without a ticket, the confirmed requirement and the scope notes are the Spec source.

## Session record

`~/.native-routed/notes/<topic>/session.json` tells `native-watch-codex` which session runs this topic and where its work lives:

```json
{
  "version": 1,
  "host": "codex",
  "skill": "native-routed-codex",
  "topic": "<topic>",
  "sessionId": "<value of CODEX_THREAD_ID>",
  "repo": "<git rev-parse --show-toplevel>",
  "baseline": "<full SHA>",
  "worktrees": [{ "path": "<absolute path>", "branch": "<branch>" }],
  "status": "running",
  "startedAt": "<ISO time>",
  "updatedAt": "<ISO time>"
}
```

- Take the id from `CODEX_THREAD_ID` only. Other session variables in the environment, such as `CLAUDE_CODE_SESSION_ID`, can be inherited from a parent process and don't identify this session. If `CODEX_THREAD_ID` is unset, write `null`; the watch can then report on the run but not relay to it.
- Update `worktrees` as they are created and removed, and set `status` to `done` or `stopped` at wrap-up.
- Write the whole file to `session.json.tmp`, then rename it over `session.json`.

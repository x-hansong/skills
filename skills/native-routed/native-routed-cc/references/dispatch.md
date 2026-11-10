# Dispatch and waiting

All agents are subagents started with the Agent tool. They see none of this conversation: everything they need is in the brief or in files the brief names.

## Starting a subagent

| Parameter | Value |
| --- | --- |
| `subagent_type` | `general-purpose` for every role; it has the tools to read, edit, run tests and commit |
| `description` | Role and unit, e.g. `worker: unit B parser` |
| `model` | The role's resolved model; omit it for a worker that inherits the default |
| `prompt` | The brief. Long briefs go to a file under the notes directory and the prompt points to it |
| `isolation` | `"worktree"` for an independent unit that runs in parallel; omit for serial units, reviews, research and the committee |
| `run_in_background` | Leave the default (background) |

Start parallel units with several Agent calls in one message.

A worktree subagent reports where its worktree and branch are. Record both in `session.json` before dispatching anything that depends on them. A worktree left unchanged is removed automatically; one with commits stays until this session removes it with `git worktree remove <path>`. Afterwards delete the parent worktrees directory the host created inside the repo (for example `.claude/worktrees/`) if it is empty, so no stray directory is left behind.

## Waiting

Background subagents notify this session when they finish. Wait for the notification; don't poll, and don't describe a result before it arrives. While agents run, keep to orchestration work that doesn't depend on them, or tell the user what is running and stop.

## Follow-ups

`SendMessage` to a running or finished subagent continues it with its context. Use it for clarifying questions and missing information. Review fixes always go to a fresh worker, never back to the author.

## Read-only agents

Reviewers, researchers and committee members get a brief that says read-only: no edits, no commits, no branch switches, no worktrees. To review a branch, they read it through git (`git diff <baseline>..<branch>`, `git show`) instead of checking it out. After each one finishes, run `git status` in every tree it could reach; any change is a finding to report, and is undone only with the user's agreement.

## Passing methods

Subagents get the test discipline and the review method as files: the copies in `~/.native-routed/notes/<topic>/`, passed by path. Never point a subagent at a skill's install path, and never ask it to load a skill the user has to run by hand.

The review method reports two axes, Standards and Spec. Without a ticket, the confirmed requirement and the scope notes are the Spec source.

## Session record

`~/.native-routed/notes/<topic>/session.json` tells `native-watch-cc` which session runs this topic and where its work lives:

```json
{
  "version": 1,
  "host": "claude-code",
  "skill": "native-routed-cc",
  "topic": "<topic>",
  "sessionId": "<value of CLAUDE_CODE_SESSION_ID>",
  "sessionName": "<this session's name from ListAgents>",
  "repo": "<git rev-parse --show-toplevel>",
  "baseline": "<full SHA>",
  "worktrees": [{ "path": "<absolute path>", "branch": "<branch>" }],
  "status": "running",
  "startedAt": "<ISO time>",
  "updatedAt": "<ISO time>"
}
```

- `sessionName` is the name `ListAgents` reports for this session ("This session is …"). If `ListAgents` isn't available, write `null`; the watch can then report on the run but not relay to it.
- Update `worktrees` as they are created and removed, and set `status` to `done` or `stopped` at wrap-up.
- Write the whole file to `session.json.tmp`, then rename it over `session.json`.

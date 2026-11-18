# Paseo access and waiting

Prefer the Paseo tools exposed in this session (`list_profiles`, `create_agent`, ...). When they are missing, use the installed `paseo` CLI. Check actual flags with `paseo --help` and each subcommand's `--help`.

## Confirm the target daemon

The local daemon's home defaults to `~/.paseo`. Environment variables can point the CLI at another daemon, so pass the home explicitly and confirm before dispatching:

```bash
paseo --home "$HOME/.paseo" daemon status --json
paseo --home "$HOME/.paseo" daemon config get daemon.agentProfiles --json
```

With MCP tools, read `list_hosts` and `list_profiles`. For a remote host, keep `{ serverId, agentId }` together, and make sure workspaces and paths belong to that host. Use a remote host only when the user asks for it; a local project path is not a remote path.

## Expand a profile

Profiles are launch templates. Read them fresh before each dispatch; never pass only the name or reuse a model remembered from earlier.

| Profile field | MCP `create_agent` field |
| --- | --- |
| `provider`, `model` | joined as `provider/model` |
| `modeId` | `settings.modeId` |
| `thinkingOptionId` | `settings.thinkingOptionId` |
| `featureValues` | `settings.features` |

`create_agent` rejects a bare provider such as `claude`; it must read `provider/model`, for example `codex/gpt-5.4`, both taken from the profile you just read.

Copy only fields that exist. CLI `--provider`, `--mode`, `--thinking` cover the first three. When a feature setting has no CLI flag, check the subcommand help or use MCP to pass it in full, and report the gap.

## Workspaces and dispatch

Pick the workspace by what the agent does:

| Work | Workspace |
| --- | --- |
| Exploration, research, review, diagnosis, or a task with no repository | Your current workspace: omit `workspaceId` in `create_agent` (CLI: omit `--workspace`/`--new-workspace`). |
| Implementation in a repository | A `worktree` workspace on that repository with its own branch, baseline pinned to a full SHA; independent units each get their own. |

Never call `create_workspace` with `isolation: "local"` on the notes directory or any other path just to give an agent somewhere to run: a path no project owns becomes a new Paseo project and workspace. The notes path goes in the brief, not in the workspace. If the project needs extra registration or restore steps for worktrees, run them on create and on resume.

For a worktree, MCP: `create_workspace`, then `create_agent` with the same `serverId` and `workspaceId`. CLI:

```bash
paseo --home "$HOME/.paseo" workspace create --help
paseo --home "$HOME/.paseo" run --help
```

`paseo run` takes `--workspace`, the profile's `--provider`, `--mode`, `--thinking`, and `--no-wait --json` for long tasks to get the agent id. Pass the prompt as one safely quoted argument; keep long briefs in a shared file and pass its path.

Follow-ups to a running agent go through `paseo send`, which waits for the agent's turn to finish unless you pass `--no-wait`. Write a long or multi-line message to a file and pass `--prompt-file <path>`. When you write that file with a heredoc, pick a delimiter that never appears as a line in the message.

## Completion

MCP dispatch sets `notifyOnFinish`; wait for the notification instead of polling. MCP agent tools resolve only the full agent id, never a short prefix (`Agent not found` is the symptom); record full ids in `progress.md` when the agent is created. Don't poll `list_agents` for state in a loop. A finish notification that reaches you mid-turn can still go unanswered, so reconcile instead: at the start of every turn, and before you tell the user an agent is still running, run `scripts/live-agents.sh <notes_dir>/<topic>` from this skill's dir. It reads the agent IDs under live resources in `progress.md`, calls `paseo ls` once and prints each agent's status. Exit 0: every listed agent is running. Exit 3: a listed agent is idle, error, closed or missing; treat that as a finish notification you missed and apply acceptance to it now. Exit 1: `paseo ls` or the notes failed; tell the user, and don't assume the agents are running. When you must list otherwise, filter: `cwd` for one workspace, `statuses` for running or errored agents, `limit` and `sinceHours` to bound it; background and archived agents appear only with `includeBackground` and `includeArchived`. CLI `run --no-wait` has no such callback: run `paseo wait <agent-id>` in the background, then read `paseo logs <agent-id>`, its status and its artifacts. A CLI wait process is not an MCP notification.

## Passing methods to agents

Agents get the test discipline, the review method and the design principles as files: the copies in the shared notes directory, passed by path together with the full baseline SHA, project path and acceptance source. Never point an agent at a skill's install path, and never ask it to load a skill the user has to run by hand.

The review method reports two axes, Standards and Spec. Without a ticket, the confirmed requirement or the shared acceptance notes are the Spec source.

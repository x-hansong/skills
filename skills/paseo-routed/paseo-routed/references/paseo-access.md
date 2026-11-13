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

Copy only fields that exist. CLI `--provider`, `--mode`, `--thinking` cover the first three. When a feature setting has no CLI flag, check the subcommand help or use MCP to pass it in full, and report the gap.

## Workspaces and dispatch

Create or pick workspaces per the `paseo` skill. Independent work units get their own worktree and branch, with the baseline pinned to a full SHA. If the project needs extra registration or restore steps for worktrees, run them on create and on resume.

MCP: `create_workspace`, then `create_agent` with the same `serverId` and `workspaceId`. CLI:

```bash
paseo --home "$HOME/.paseo" workspace create --help
paseo --home "$HOME/.paseo" run --help
```

`paseo run` takes `--workspace`, the profile's `--provider`, `--mode`, `--thinking`, and `--no-wait --json` for long tasks to get the agent id. Pass the prompt as one safely quoted argument; keep long briefs in a shared file and pass its path.

Follow-ups to a running agent go through `paseo send`, which waits for the agent's turn to finish unless you pass `--no-wait`. Write a long or multi-line message to a file and pass `--prompt-file <path>`. When you write that file with a heredoc, pick a delimiter that never appears as a line in the message.

## Completion

MCP dispatch sets `notifyOnFinish`; wait for the notification instead of polling. MCP agent tools resolve only the full agent id, never a short prefix; record full ids in `progress.md`. CLI `run --no-wait` has no such callback: run `paseo wait <agent-id>` in the background, then read `paseo logs <agent-id>`, its status and its artifacts. A CLI wait process is not an MCP notification.

## Passing methods to agents

Agents get the test discipline, the review method and the design principles as files: the copies in the shared notes directory, passed by path together with the full baseline SHA, project path and acceptance source. Never point an agent at a skill's install path, and never ask it to load a skill the user has to run by hand.

The review method reports two axes, Standards and Spec. Without a ticket, the confirmed requirement or the shared acceptance notes are the Spec source.

# Detection

Run these read-only checks in order. Pass `--home "$HOME/.paseo"` to every `paseo daemon config` and `paseo daemon status` call so environment variables can't redirect them to another daemon. Later checks depend on earlier ones; when a prerequisite fails, mark the dependants ❌ "blocked by <check>" instead of running them.

| # | Check | How | ✅ when |
| --- | --- | --- | --- |
| 1 | Paseo CLI | `command -v paseo` and `paseo --version` | Found. ❌ otherwise; fix: `npm install -g @getpaseo/cli` |
| 2 | Daemon | `paseo daemon status --home "$HOME/.paseo" --json` | `localDaemon` is `running`. Compare the daemon version with the CLI version; a mismatch is ⚠️ (fix: restart the daemon after upgrading) |
| 3 | MCP server | `paseo daemon config get daemon.mcp.enabled --home "$HOME/.paseo" --json` | `value` is `true`, or `set` is `false` (defaults to on) |
| 4 | MCP injected into agents | `paseo daemon config get daemon.mcp.injectIntoAgents --home "$HOME/.paseo" --json` | `value` is `true`. Defaults to off, so unset is ❌. Without it, dispatched agents can't use Paseo tools |
| 5 | Providers | `paseo provider ls --json` | At least one provider is available |
| 6 | Profiles | `paseo daemon config get daemon.agentProfiles --home "$HOME/.paseo" --json` | At least one profile fit for `worker` and one for `reviewer`. List every profile's `name`, `provider`, `model`, `modeId`, and whether it has `notes` |
| 7 | Roster config | Read `~/.paseo-routed/config.yaml` | Parses; has `default_roster`, which exists under `rosters`; every roster has `worker` and `reviewer`. ⚠️ when it parses but has problems; list each one |
| 8 | Roster profiles exist | Each roster's `worker` and `reviewer` against check 6 | Every name matches a profile exactly. Each unmatched name is a problem |
| 9 | Notes directory | `notes_dir` from the config, default `~/.paseo-routed/notes` | Exists and is writable |
| 10 | Skills | See below | All present for every agent the user uses |

## Skills check

Required skills and where they come from:

| Skill | Needed by | Install |
| --- | --- | --- |
| `paseo`, `paseo-advisor`, `paseo-committee` | all routed skills | `npx skills add getpaseo/paseo` (or Paseo app: Settings → host → Agents → Orchestration skills) |
| `paseo-routed`, `implement-routed`, `implement-spec-routed`, `paseo-routed-guide` | this skill set | `npx skills add x-hansong/skills --skill <name>` |

Look for `<skill>/SKILL.md` in each agent's skill directories, global and project: Claude Code `~/.claude/skills/` and `.claude/skills/`; Codex `~/.agents/skills/` and `.agents/skills/`. Report per agent. A skill present for only one of the user's agents is ⚠️. Skills in this session's available-skills list count as present for this agent.

## Profile fitness

A profile fits `worker` when its `notes` or name describe implementation, exploration or general coding, and `reviewer` when they describe review, diagnosis or critique. When notes are missing, propose the fit from the model and ask; don't decide silently. A reviewer whose `modeId` allows writes (`bypassPermissions`, `full-access`) is fine, but say so in the report: routed skills keep it read-only through the brief and a `git status` check.

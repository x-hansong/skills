# Detection

Run these read-only checks in order. When a prerequisite fails, mark the checks that depend on it ❌ "blocked by <check>" instead of running them.

| # | Check | How | ✅ when |
| --- | --- | --- | --- |
| 1 | Git | `git --version` | Found |
| 2 | Agent tool models | This session's Agent tool schema: the values its `model` parameter accepts | The tool exists and accepts a `model`. List the values |
| 3 | What the aliases resolve to | `CLAUDE_CODE_SUBAGENT_MODEL` and `ANTHROPIC_DEFAULT_<ALIAS>_MODEL` in the environment; read only these variables | Always ✅; this row is information. Show alias → model, and which model a subagent without `model` gets. Unset variables mean the host's built-in mapping |
| 4 | Watch tools | `ListAgents`, `SendMessage`, `CronCreate`, `CronDelete` in this session's tools | All present. Missing ones are ⚠️: only `native-watch-cc` needs them |
| 5 | Config | Read `~/.native-routed/config.yaml` | Missing is ✅ "defaults apply". Otherwise it parses, `version` is `1`, and the `cc:` section, when present, has only `worker`, `reviewer`, `committee`. ❌ when it doesn't parse |
| 6 | Config values | Each value in `cc:` against check 2 | Every value is accepted; `committee` has exactly two entries. Each bad value is a problem |
| 7 | Notes directory | `~/.native-routed/notes/` | Exists and is writable, or doesn't exist yet (⚠️, created on write) |
| 8 | Skills | See below | All present for Claude Code |

When the user wants proof that a model value really takes effect, offer to start one subagent per distinct value with a one-line prompt asking it to report its exact model id. It costs a few tokens; run it only when the user agrees, and report the results in row 3.

## Skills check

| Skill | Needed by | Install |
| --- | --- | --- |
| `native-routed-cc`, `native-implement-routed-cc`, `native-implement-spec-routed-cc`, `native-watch-cc`, `native-routed-guide-cc` | this skill set | `npx skills add x-hansong/skills --skill <name>` |

A skill counts as present when it is in this session's available-skills list, or when `<skill>/SKILL.md` exists in Claude Code's global or project skill directory (`~/.claude/skills/`, `.claude/skills/`).

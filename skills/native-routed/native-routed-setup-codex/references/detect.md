# Detection

Run these read-only checks in order. When a prerequisite fails, mark the checks that depend on it ❌ "blocked by <check>" instead of running them.

| # | Check | How | ✅ when |
| --- | --- | --- | --- |
| 1 | Git | `git --version` | Found |
| 2 | Multi-agent | `codex features list`, row `multi_agent`; and `spawn_agent`, `wait_agent` in this session's tools | The feature is `true` and both tools are present. Feature on but tools missing: ⚠️ "start a new session" |
| 3 | Subagent models | This session's `spawn_agent` schema: the values `model` and `reasoning_effort` accept | Both lists are readable. List them |
| 4 | Session model | `model` and `model_reasoning_effort` in Codex's `config.toml`; read only these keys | Always ✅; this row is information: what a worker without `model` runs on |
| 5 | Config | Read `~/.native-routed/config.yaml` | Parses, `version` is `1`, and has a `codex:` section with `reviewer` and `committee`. Missing file or section is ❌ "run the plan to create it" |
| 6 | Config values | Each value in `codex:` against check 3 | Every model and effort is accepted, or is `inherit`; `budget` is `small`, `medium`, `large` or `unlimited`; `committee` has two or more entries. Each bad value is a problem |
| 7 | Notes directory | `~/.native-routed/notes/` | Exists and is writable, or doesn't exist yet (⚠️, created on write) |
| 8 | Watch support | `codex queue --help` succeeds; `automation_update` in this session's tools | `codex queue` works. Without `automation_update` the row is ⚠️ "watch patrols on demand only (`now`)"; that is expected in the CLI |
| 9 | Skills | See below | All present for Codex |

## Skills check

| Skill | Needed by | Install |
| --- | --- | --- |
| `native-routed-codex`, `native-implement-routed-codex`, `native-implement-spec-routed-codex`, `native-watch-codex`, `native-routed-guide-codex` | this skill set | `npx skills add x-hansong/skills --skill <name>` |

A skill counts as present when it is in this session's available-skills list, or when `<skill>/SKILL.md` exists in Codex's global or project skill directory (`~/.agents/skills/`, `.agents/skills/`).

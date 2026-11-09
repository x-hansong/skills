# Model resolution

Each role runs on a model the Agent tool accepts in its `model` parameter (aliases such as `opus`, `sonnet`, `haiku`, `fable`; check this session's Agent tool schema for the exact list).

## Sources, first match wins

1. Arguments: `--worker <model>`, `--reviewer <model>` (remove them from the task text).
2. The `cc:` section of `~/.native-routed/config.yaml`, written by `native-routed-setup-cc`.
3. Defaults:

| Role | Default | Why |
| --- | --- | --- |
| `worker` | no `model` parameter | Inherits this host's subagent default |
| `reviewer` | `opus` | Reviews and diagnosis go to a strong reasoning model |
| `committee` | `opus` and `fable` | Two strong models, so the two diagnoses are independent |

When `CLAUDE_CODE_SUBAGENT_MODEL` is set, a subagent started without `model` runs on it; an explicit `model` overrides it. So the worker follows that variable and the reviewer doesn't.

## Config file

```yaml
version: 1
cc:
  worker: sonnet            # optional; omit to inherit the subagent default
  reviewer: opus
  committee: [opus, fable]  # exactly two entries
codex:
  # written by native-routed-setup-codex; this skill ignores it
```

- A missing file or a missing `cc:` section means the defaults apply.
- A file that doesn't parse, or `version` other than `1`: stop and tell the user the path and the error. Suggest `native-routed-setup-cc check`.
- A value the Agent tool doesn't accept, or a `committee` without exactly two entries: stop and name the bad key. Don't substitute another model.

## Record

Write each role's resolved model, and where it came from (argument, config or default), to the run's `scope.md`.

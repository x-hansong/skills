# Model resolution

Each role runs on a model the Agent tool accepts in its `model` parameter (aliases such as `opus`, `sonnet`, `haiku`, `fable`; check this session's Agent tool schema for the exact list) and, optionally, an effort its `effort` parameter accepts.

## Sources, first match wins

1. Arguments: `--worker <model>[/<effort>]`, `--reviewer <model>[/<effort>]`, `--budget <budget>` (remove them from the task text).
2. The `cc:` section of `~/.native-routed/config.yaml`, written by `native-routed-setup-cc`.
3. Defaults:

| Role | Default | Why |
| --- | --- | --- |
| `worker` | `inherit` | Inherits this host's subagent default |
| `reviewer` | `opus` | Reviews and diagnosis go to a strong reasoning model |
| `committee` | `opus` and `fable` | Two strong models, so the two diagnoses are independent |

When `CLAUDE_CODE_SUBAGENT_MODEL` is set, a subagent started without `model` runs on it; an explicit `model` overrides it. So `inherit` follows that variable and an explicit model doesn't.

## Values

A role is a model, `inherit`, or `{ model: <model or inherit>, effort: <effort> }`. `committee` is a list of these.

- `inherit` means no `model` parameter, so the subagent runs on the host's subagent default.
- `committee` has two or more entries, one member per entry, so its length sets how many members run.
- Effort: the role's own `effort` wins; otherwise the budget's effort; with neither, leave the effort parameter out.

## Budget

`budget` sets the effort of every role that doesn't set its own:

| Budget | Effort |
| --- | --- |
| `small` | `medium` |
| `medium` | `high` |
| `large` | `xhigh` |
| `unlimited` | `max` |

The ladder is `max` > `xhigh` > `high` > `medium` > `low`. When the host doesn't accept the budget's effort, use the highest effort it accepts below that one, and record the substitution.

## Config file

```yaml
version: 1
cc:
  budget: medium            # optional
  worker: sonnet            # optional; omit or `inherit` for the subagent default
  reviewer: { model: opus, effort: xhigh }
  committee: [opus, fable]  # two or more entries
codex:
  # written by native-routed-setup-codex; this skill ignores it
```

- A missing file or a missing `cc:` section means the defaults apply.
- A file that doesn't parse, or `version` other than `1`: stop and tell the user the path and the error. Suggest `native-routed-setup-cc check`.
- A model or effort the Agent tool doesn't accept, an unknown `budget`, or a `committee` with fewer than two entries: stop and name the bad key. Don't substitute another value.

## Model rejected mid-run

A value that passed these checks can still fail when a subagent starts, for example when the model is withdrawn or over quota. Then fall back in this order, skipping any value that already failed in this run:

1. the role's default from the table above, when it differs from the failed value;
2. `inherit`.

Never fall back silently. Record each fallback (role, configured value, value used, the error) in `scope.md` and list it in the final report. When the reviewer falls back to the worker's model, say that the review is no longer independent.

## Record

Write each role's resolved model and effort, and where they came from (argument, config, budget or default), to the run's `scope.md`.

# Model resolution

Each role runs on a model and reasoning effort that `spawn_agent` accepts in its `model` and `reasoning_effort` parameters. Check this session's `spawn_agent` schema for the exact lists; model names differ between machines and accounts, so this skill ships none.

## Sources, first match wins

1. Arguments: `--worker <model>[/<effort>]`, `--reviewer <model>[/<effort>]`, `--budget <budget>` (remove them from the task text).
2. The `codex:` section of `~/.native-routed/config.yaml`, written by `native-routed-setup-codex`.

There are no built-in defaults for `reviewer` and `committee`. If the config file or its `codex:` section is missing, stop and tell the user to run `native-routed-setup-codex`. Don't pick a model yourself.

## Values

A role is a model, `inherit`, or `{ model: <model or inherit>, effort: <effort> }`. `committee` is a list of these.

- `inherit` means no `model` parameter, so the subagent runs on this session's model.
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
codex:
  budget: medium                             # optional
  worker: { effort: medium }                 # optional; without model, the worker uses this session's model
  reviewer: { model: <strong-model>, effort: high }
  committee:                                 # two or more entries, ideally different models
    - { model: <strong-model>, effort: high }
    - { model: <other-strong-model>, effort: high }
cc:
  # written by native-routed-setup-cc; this skill ignores it
```

- `worker` is optional; without it the worker is `inherit`.
- `reviewer` and `committee` are required.
- A file that doesn't parse, or `version` other than `1`: stop and tell the user the path and the error.
- A model or effort that `spawn_agent` doesn't accept, an unknown `budget`, or a `committee` with fewer than two entries: stop and name the bad key. Suggest `native-routed-setup-codex check`. Don't substitute another value.

## Model rejected mid-run

A value that passed these checks can still fail when a subagent starts, for example when the model is withdrawn or over quota. Then fall back in this order, skipping any value that already failed in this run:

1. for a committee member or the reviewer, another committee entry; for the worker, `inherit`;
2. `inherit`.

Never fall back silently. Record each fallback (role, configured value, value used, the error) in `scope.md` and list it in the final report. When the reviewer falls back to the worker's model, say that the review is no longer independent.

## Record

Write each role's resolved model and effort, and where they came from (argument, config, budget or default), to the run's `scope.md`.

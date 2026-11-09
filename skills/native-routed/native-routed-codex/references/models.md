# Model resolution

Each role runs on a model and reasoning effort that `spawn_agent` accepts in its `model` and `reasoning_effort` parameters. Check this session's `spawn_agent` schema for the exact lists; model names differ between machines and accounts, so this skill ships none.

## Sources, first match wins

1. Arguments: `--worker <model>[/<effort>]`, `--reviewer <model>[/<effort>]` (remove them from the task text).
2. The `codex:` section of `~/.native-routed/config.yaml`, written by `native-routed-setup-codex`.

There are no built-in defaults for `reviewer` and `committee`. If the config file or its `codex:` section is missing, stop and tell the user to run `native-routed-setup-codex`. Don't pick a model yourself.

## Config file

```yaml
version: 1
codex:
  worker: { effort: medium }                 # optional; without model, the worker uses this session's model
  reviewer: { model: <strong-model>, effort: high }
  committee:                                 # exactly two entries, ideally two different models
    - { model: <strong-model>, effort: high }
    - { model: <other-strong-model>, effort: high }
cc:
  # written by native-routed-setup-cc; this skill ignores it
```

- `worker` is optional. Without `model`, omit the parameter so the worker runs on this session's model; without `effort`, omit `reasoning_effort` too.
- `reviewer` and `committee` are required.
- A file that doesn't parse, or `version` other than `1`: stop and tell the user the path and the error.
- A model or effort that `spawn_agent` doesn't accept, or a `committee` without exactly two entries: stop and name the bad key. Suggest `native-routed-setup-codex check`. Don't substitute another value.

## Record

Write each role's resolved model and effort, and where they came from (argument or config), to the run's `scope.md`.

# Roster resolution

A **roster** maps the abstract roles `worker` and `reviewer` to Paseo profile names. Switching rosters switches which models and harnesses do the work, without touching any skill.

## Config file

`~/.paseo-routed/config.yaml`, written by the `setup-paseo-routed` skill:

```yaml
version: 1
default_roster: main
rosters:
  main:
    worker: Builder        # Paseo profile name
    reviewer: Critic
  alt:
    worker: Builder-alt
    reviewer: Critic-alt
    compare: true          # optional: keep a comparison log
notes_dir: ~/.paseo-routed/notes
preferences: |
  Optional free-form rules the user wants applied on every routed run.
```

## Resolve

1. Read the config file. If it doesn't exist or isn't valid YAML, stop and tell the user to run `/setup-paseo-routed`.
2. Pick the roster name, first match wins:
   - `--roster <name>` in the task arguments (remove it from the task text);
   - the user naming a roster in the request ("use the alt roster");
   - `default_roster`.
3. If that name is not under `rosters`, stop and list the roster names that do exist. Don't guess a near match.
4. Take `worker` and `reviewer` from the roster. Both are required. Any role this skill or a calling skill mentions beyond these two (explorer, merger, fixer) uses the `worker` profile.
5. Call `list_profiles` (or the CLI fallback in [Paseo access](paseo-access.md)) and find each profile by exact `name`. If either is missing or has no `provider`, stop and tell the user which one; suggest `/setup-paseo-routed`. Don't substitute another profile.
6. Read both profiles' `notes` and follow them.
7. Apply `preferences` as extra rules for this run. If they conflict with this skill, follow the user's preferences and say so.
8. Write the resolved roster name and each role's profile name and model to the shared notes.

## Read-only reviewer

A reviewer profile may run in a mode that allows writes (`bypassPermissions`, `full-access`). Every review brief states that the review is read-only, and after the review this session checks that `git status` in the reviewer's worktree shows no changes.

## Comparison log

When the roster has `compare: true`, additionally record in the shared notes: the roster and profile names and models used, the number of rework rounds per work unit, and the reviewer's finding count and fix rounds. This lets the user compare rosters across runs.

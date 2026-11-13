---
name: native-routed-setup-cc
description: "Set up, or health-check, what the native-routed Claude Code skills need: the cc section of ~/.native-routed/config.yaml (budget, and which model and effort play worker, reviewer and committee), the notes directory, the host tools the skills use, and the skills they depend on, and an Explore subagent that follows CLAUDE_CODE_SUBAGENT_MODEL. Detects what exists, suggests defaults, writes only after confirmation, and re-checks. Safe to rerun; rerunning is the health check."
argument-hint: "[check | budget=<budget> | <role>=<model>[/<effort>] ...]"
disable-model-invocation: true
license: MIT
compatibility: "Claude Code only, on macOS or Linux. No Paseo needed."
metadata:
  author: x-hansong
---

# Setup Native Routed (Claude Code)

Get this machine ready for `native-routed-cc`, `native-implement-routed-cc`, `native-implement-spec-routed-cc` and `native-watch-cc`, or check that it still is. Reply in the user's language.

The routed skills run without a config: they fall back to the defaults in their model reference. This skill writes a config when the user wants different models, and checks everything else either way.

Explore read-only, present what you found, propose a plan, confirm with the user, then write and re-check.

- `check`: stop after the report, and write nothing.
- `budget=<budget>` and `<role>=<model>[/<effort>]` arguments (`budget=medium`, `worker=inherit`, `reviewer=opus/xhigh`, `committee=opus,fable`): skip the suggestions and plan exactly these changes; still confirm before writing.

## 1. Detect (read-only)

Run every check in [detection](references/detect.md) and keep the raw results. Don't install, create or edit anything in this step.

## 2. Report

Show one table, one row per check: ✅ ready, ⚠️ partial, ❌ missing, with the evidence in a few words. Then summarise in one line, for example "7 of 9 ready, 1 partial, 1 missing".

If everything is ✅ and the user asked for nothing else, say so and stop. That is the health-check result.

## 3. Plan

For every ⚠️ and ❌, and for any role the user wants changed, propose the smallest change that fixes it: the exact command, or the file and its new content as a diff.

- **Models.** Suggest one value per role from the models the Agent tool accepts (check 2), with one sentence of reasoning each:
  - `worker`: leave unset, so it inherits the subagent default, unless the user wants a specific model;
  - `reviewer`: the strongest reasoning model available, ideally a different model from the one the worker resolves to;
  - `committee`: two strong models, different from each other when possible; each extra entry adds one more member to every committee run.

  Use check 3 to say which real model each alias resolves to here. Never suggest a value the Agent tool doesn't accept, and never a model name from memory. The user can edit any line.
- **Budget.** Ask which budget to use, with the structured-question tool when there is one: `small` (medium effort), `medium` (high), `large` (xhigh), `unlimited` (max), or none to keep the host's default effort. Name the current budget when the config has one. A role with its own `effort` keeps it. The mapping is in the `native-routed-cc` model reference.
- **Fill gaps only.** Never remove an existing key. Changing an existing value needs its own line in the plan with the old and new value. Leave the `codex:` section and any other section untouched.
- **Skills.** Missing skills are installed with `npx skills add … -a claude-code`; ask once for scope (`-g` global or project).
- **Explore model.** For check 9, follow the plan section of [Explore model](references/explore-model.md).

Show the whole plan, then ask the user to confirm or edit it. Don't write until they confirm.

## 4. Write

Apply the confirmed plan in this order, stopping at the first failure and reporting it:

1. **Back up** `~/.native-routed/config.yaml`, when it exists, to `config.yaml.bak-<timestamp>` in the same directory.
2. **Config:** write the new file to `config.yaml.tmp`, then rename it over `config.yaml`. The shape is in [config example](references/config.example.yaml). A new file gets `version: 1`.
3. **Notes directory:** create `~/.native-routed/notes/` if missing.
4. **Skills:** run the confirmed `npx skills add` commands.
5. **Explore model:** write the confirmed `Explore.md` as described in [Explore model](references/explore-model.md).

## 5. Re-check

Run the detection again and show the new table next to the old one. Everything the plan covered must now be ✅. Parse the written config back and compare it with the plan; if anything differs or a check isn't ✅, say so plainly with the evidence and show how to restore the backup. Don't report success.

End with one line on how to override a model for a single run (`--reviewer <model>`), then point to `native-routed-guide-cc` for a first run.

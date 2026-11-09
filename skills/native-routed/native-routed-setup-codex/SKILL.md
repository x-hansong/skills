---
name: native-routed-setup-codex
description: "Set up, or health-check, what the native-routed Codex skills need: the codex section of ~/.native-routed/config.yaml (which model and reasoning effort play worker, reviewer and committee), the multi_agent feature, the notes directory, and the skills they depend on. Detects what exists, suggests defaults from the models this Codex offers, writes only after confirmation, and re-checks. Required before the first native-routed-codex run; rerunning is the health check."
argument-hint: "[check | <role>=<model>[/<effort>] ...]"
disable-model-invocation: true
license: MIT
compatibility: "Codex only, on macOS or Linux. No Paseo needed."
metadata:
  author: x-hansong
---

# Setup Native Routed (Codex)

Get this machine ready for `native-routed-codex`, `native-implement-routed-codex`, `native-implement-spec-routed-codex` and `native-watch-codex`, or check that it still is. Reply in the user's language.

The routed skills stop without a `codex:` config: model names differ between machines and accounts, so they ship no defaults. This skill suggests values from what this Codex actually offers and writes them after the user confirms.

Explore read-only, present what you found, propose a plan, confirm with the user, then write and re-check.

- `check`: stop after the report, and write nothing.
- `<role>=<model>[/<effort>]` arguments (`reviewer=<model>/high`, `committee=<model>/high,<model>/high`): skip the suggestions and plan exactly these changes; still confirm before writing.

## 1. Detect (read-only)

Run every check in [detection](references/detect.md) and keep the raw results. Don't install, create or edit anything in this step.

## 2. Report

Show one table, one row per check: ✅ ready, ⚠️ partial, ❌ missing, with the evidence in a few words. Then summarise in one line, for example "6 of 9 ready, 1 partial, 2 missing".

If everything is ✅ and the user asked for nothing else, say so and stop. That is the health-check result.

## 3. Plan

For every ⚠️ and ❌, and for any role the user wants changed, propose the smallest change that fixes it: the exact command, or the file and its new content as a diff.

- **Models.** Suggest one model and effort per role from the values `spawn_agent` accepts (check 3), with one sentence of reasoning each:
  - `worker`: leave `model` unset so it uses this session's model; effort unset, or the session's default effort;
  - `reviewer`: the strongest reasoning model offered, at `high` effort, ideally a different model from the worker's;
  - `committee`: two strong models at `high`, different from each other when possible.

  Judge strength from what the schema and the model names say, state that it is a judgement, and let the user correct it. Never suggest a value `spawn_agent` doesn't accept, and never a model name from memory.
- **Fill gaps only.** Never remove an existing key. Changing an existing value needs its own line in the plan with the old and new value. Leave the `cc:` section and any other section untouched.
- **Feature.** If `multi_agent` is off, propose `codex features enable multi_agent` (or the equivalent `config.toml` line the CLI reports), backing up `config.toml` first. A new session is needed before the routed skills can use it.
- **Skills.** Missing skills are installed with `npx skills add … -a codex`; ask once for scope (`-g` global or project).

Show the whole plan, then ask the user to confirm or edit it. Don't write until they confirm.

## 4. Write

Apply the confirmed plan in this order, stopping at the first failure and reporting it:

1. **Back up** `~/.native-routed/config.yaml`, when it exists, to `config.yaml.bak-<timestamp>` in the same directory; back up Codex's `config.toml` the same way before a feature change.
2. **Feature:** apply the confirmed feature change.
3. **Config:** write the new file to `config.yaml.tmp`, then rename it over `config.yaml`. The shape is in [config example](references/config.example.yaml). A new file gets `version: 1`.
4. **Notes directory:** create `~/.native-routed/notes/` if missing.
5. **Skills:** run the confirmed `npx skills add` commands.

## 5. Re-check

Run the detection again and show the new table next to the old one. Everything the plan covered must now be ✅. Parse the written config back and compare it with the plan; if anything differs or a check isn't ✅, say so plainly with the evidence and show how to restore the backup. Don't report success.

End with one line on how to override a model for a single run (`--reviewer <model>/<effort>`), then point to `native-routed-guide-codex` for a first run.

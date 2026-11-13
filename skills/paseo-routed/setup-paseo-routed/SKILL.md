---
name: setup-paseo-routed
description: "Set up, or health-check, everything the paseo-routed skills need: the Paseo CLI and daemon, MCP injection, worker and reviewer profiles, the roster config at ~/.paseo-routed/config.yaml, the skills they depend on, and, with Claude Code, an Explore subagent that follows CLAUDE_CODE_SUBAGENT_MODEL. Detects what already exists, proposes a plan that only fills the gaps, and writes after confirmation. Safe to rerun; rerunning is the health check."
argument-hint: "[check]"
disable-model-invocation: true
license: MIT
compatibility: "Claude Code or Codex on macOS or Linux. Needs Node.js (Paseo already requires it) for the bundled profile script."
metadata:
  author: x-hansong
---

# Setup Paseo Routed

Get a machine ready for `paseo-routed`, `implement-routed` and `implement-spec-routed`, or check that it still is. Reply in the user's language.

This is a prompt-driven skill. Explore read-only, present what you found, propose a plan, confirm with the user, then write and re-check. With the argument `check`, or when another skill asks for a check only, stop after the report and the plan, and write nothing.

## 1. Detect (read-only)

Run every check in [detection](references/detect.md) and keep the raw results. Don't install, start or edit anything in this step.

## 2. Report

Show one table, one row per check: ✅ ready, ⚠️ partial, ❌ missing, with the evidence in a few words. Then summarise in one line, for example "4 of 11 ready, 2 partial, 5 missing".

If everything is ✅, say so and stop. That is the health-check result.

## 3. Plan

For every ⚠️ and ❌, propose the smallest change that fixes it: the exact command, file and content or diff. Rules:

- **Fill gaps only.** Never remove or rename an existing profile, roster, skill or setting. Changing an existing value needs its own line in the plan with the old and new value.
- **Profiles.** Before proposing a new profile, try to reuse existing ones: read every profile's `name`, `provider`, `model` and `notes` and propose which fits `worker` and which fits `reviewer`. Only when nothing fits, list the models actually available (`paseo provider models <provider> --thinking --json`) and recommend one per role: for `worker` a fast, capable coding model; for `reviewer` the strongest reasoning model, on a different model or provider from the worker when possible. The user picks. Never ship a model name from memory.
- **New profile notes** describe the role in one or two sentences, for example "Worker for paseo-routed: exploration, research, implementation, merging, review fixes. Not for reviewing its own work." and "Reviewer for paseo-routed: read-only review and hard diagnosis. Briefs must state read-only."
- **Rosters.** One roster per working worker/reviewer pair. If several pairs exist (for example the same models through two different harnesses), propose one roster each and ask which is `default_roster`.
- **Skills.** Missing skills are installed with `npx skills add`; ask for scope (`-g` global or project) and target agents (`-a claude-code`, `-a codex`) once for all of them.
- **Explore model.** For check 11, follow the plan section of [Explore model](references/explore-model.md).

Show the whole plan, then ask the user to confirm or edit it. Don't write until they confirm.

## 4. Write

Apply the confirmed plan in this order, stopping at the first failure and reporting it:

1. **Back up** before the first Paseo config change: `node <this skill's dir>/scripts/profiles.mjs backup`. Back up `~/.paseo-routed/config.yaml` to `config.yaml.bak-<timestamp>` before editing it.
2. **Paseo settings** such as MCP: `paseo daemon config set <path> <value> --home ~/.paseo --json`.
3. **Profiles** only through the bundled script, never by editing `config.json` or calling `config set daemon.agentProfiles` directly, because that command replaces the whole array. Write the new or changed profiles to a temporary JSON array and run:

   ```bash
   node <this skill's dir>/scripts/profiles.mjs upsert --file <tmp.json> --dry-run
   node <this skill's dir>/scripts/profiles.mjs upsert --file <tmp.json>
   ```

   Show the dry-run output first. The real run backs up, merges by name, writes the full array and verifies every other profile is unchanged. If it exits non-zero, stop and show its `rollback` command.
4. **Roster config:** create or edit `~/.paseo-routed/config.yaml` from the [template](references/config.example.yaml). Keep existing rosters and preferences.
5. **Notes directory:** create `notes_dir`.
6. **Skills:** run the confirmed `npx skills add` commands.
7. **Explore model:** write the confirmed `Explore.md` as described in [Explore model](references/explore-model.md).

## 5. Re-check

Run the detection again and show the new table next to the old one. Everything the plan covered must now be ✅. If anything isn't, say so plainly with the evidence; don't report success.

End with how to switch rosters: `/paseo-routed --roster <name> <task>` for one run, or change `default_roster`. Then point to `paseo-routed-guide` for a first run.

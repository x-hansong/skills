# Maintaining this repo

Skills live in `skills/<group>/<skill>/SKILL.md`. A group directory never has its own `SKILL.md`: the skills CLI stops searching below the first one it finds.

## Rules for skills

- `name` matches the directory name; `description` says what the skill does and when to use it, under 1024 characters.
- Write `SKILL.md` and references in English and tell the agent to reply in the user's language. User-facing docs get a `.zh-CN.md` twin.
- Refer to another skill by name ("load the `tdd` skill"), never by an install path such as a home-directory skills folder. Link only to files inside the same skill.
- No user-specific values: no profile or model names from a real machine, no hostnames, IPs, server ids, tokens or home paths. Examples use neutral names (`Builder`, `Critic`).
- A skill users run on purpose sets `disable-model-invocation: true` and, in `agents/openai.yaml`, `policy.allow_implicit_invocation: false`.
- Anything that writes user config shows a plan, waits for confirmation, backs up, and verifies after writing.

## Rendered skills

The `-cc` and `-codex` twins under `skills/native-routed/`, and the shared `review.md` and `tests.md` references, are rendered from `src/`. Edit `src/`, then run `scripts/render.sh`. In a template, `{host}` becomes `cc` or `codex`, and lines between `%% cc` (or `%% codex`) and `%% end` go to that host only. Keep host-specific blocks small; shared prose stays outside them.

## Checks

Run `scripts/check.sh` before committing. CI runs the same script.

## Releases

Add the change under `## Unreleased` in `CHANGELOG.md`. To release, rename that section to the new version and date, commit, and tag `vX.Y.Z`.

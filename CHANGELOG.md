# Changelog

All notable changes to this repository. Versions follow [Semantic Versioning](https://semver.org) and are tagged `vX.Y.Z`.

## Unreleased

### Added

- Paseo Routed group: `paseo-routed`, `implement-routed`, `implement-spec-routed`, `setup-paseo-routed`, `paseo-routed-guide`.
- Rosters in `~/.paseo-routed/config.yaml` map the `worker` and `reviewer` roles to Paseo profiles; switch per run with `--roster <name>`.
- `paseo-watch`: a Paseo heartbeat patrols top-level orchestrator agents and reports only what changed; every pending decision comes with its background rebuilt (task, path so far, blocker, options, what happens without an answer) and a stable `D<n>` id; answers and standing rules are relayed with explicit authorised / not-authorised scope; state persists in `~/.paseo-routed/.watch/state.json`.
- `setup-paseo-routed` detects existing setup, plans only the missing pieces, writes after confirmation and re-checks; profiles are written through a script that preserves every other profile.
- Native Routed group: the same worker / reviewer split without Paseo, on each host's own subagents. Six skills per host, suffixed `-cc` (Claude Code Agent tool) and `-codex` (Codex `spawn_agent`): `native-routed-*`, `native-implement-routed-*`, `native-implement-spec-routed-*`, `native-watch-*`, `native-routed-guide-*`, `native-routed-setup-*`.
- Native Routed models live in `~/.native-routed/config.yaml`, one section per host: the reviewer and a two-member committee run on stronger models than the worker. Codex has no built-in defaults; its setup suggests values from the models `spawn_agent` offers.
- `paseo-watch` and `native-watch-*` track idle time: an orchestrator idle past `stallMinutes` (default 30) with unfinished work is reported as stalled even when nothing else changed, and a child's progress is no longer reported as the parent's; a pending decision whose agent is about to lose its prompt cache (`cacheTtlMinutes`, default 60, provider-dependent, `null` to turn off) gets a warning, and is marked `cold` after.
- `native-watch-*` finds runs through `session.json` in `~/.native-routed/notes/<topic>/`; Claude Code patrols with `CronCreate` and relays with `SendMessage`, Codex patrols with a heartbeat automation where available (on demand otherwise) and relays with `codex queue`.

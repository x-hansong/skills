# Changelog

All notable changes to this repository. Versions follow [Semantic Versioning](https://semver.org) and are tagged `vX.Y.Z`.

## Unreleased

### Added

- Paseo Routed group: `paseo-routed`, `implement-routed`, `implement-spec-routed`, `setup-paseo-routed`, `paseo-routed-guide`.
- Rosters in `~/.paseo-routed/config.yaml` map the `worker` and `reviewer` roles to Paseo profiles; switch per run with `--roster <name>`.
- `setup-paseo-routed` detects existing setup, plans only the missing pieces, writes after confirmation and re-checks; profiles are written through a script that preserves every other profile.

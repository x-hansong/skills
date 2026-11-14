# Test discipline

Implementation workers follow this. The orchestrator copies the file into the run's notes directory and the brief points to that copy, together with the test boundary: which seams get a test, and which checks count as relevant.

## Test first, at the agreed seams

1. **Pin the behaviour.** State the intended behaviour, the current behaviour and the smallest observable reproduction or acceptance check.
2. **Pick the narrowest executable check.** Prefer the closest unit, component or integration test the project already uses for that code path. Don't build a new harness just to have a test.
3. **Write the failing test first.** Encode the intended behaviour, not the current implementation.
4. **Run it before changing production code.** Confirm it fails for the intended reason. If it passes, or fails for an unrelated reason, fix the test or the reproduction first.
5. **Make the smallest change** that satisfies the behaviour and keeps nearby contracts.
6. **Rerun** the new test, then the affected tests (the changed code's direct tests and the new tests) and the static checks on the changed files, before each commit. Don't run the project's full suite or wait on CI unless the brief asks for it; say in the report that the full suite was not run.

## When a failing test is impractical

When a test would need broad harness setup, brittle mocks, slow end-to-end infrastructure, production-only state or large unrelated fixture churn, use the closest executable check instead (a targeted script, a reproduction command, a log or snapshot assertion) and say why. No new test beats a bad one: a test that mostly exercises mocks, mirrors the implementation, depends on timing or global state, or would be deleted right after.

## Guardrails

- Don't change a test to match a wrong implementation.
- Don't weaken an assertion unless the expected behaviour really changed, and say why.
- Keep the test on the behaviour in the ticket; no unrelated coverage.
- Make a flaky case deterministic where possible, and name the signal it locks down.

## Report

- The failing-before test or check, and the failure it produced.
- The passing-after run, and the other checks run with their exit codes.
- When no failing-before evidence was possible, why, and the check used instead.

---

Adapted from [mattpocock/skills](https://github.com/mattpocock/skills), MIT License.

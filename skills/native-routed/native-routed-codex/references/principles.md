# Design principles

Three readers use this file. The orchestrator reads it before writing the decided design in an implementation brief. The reviewer applies it as a baseline on the Standards axis. The final report cites it. The orchestrator copies the file into the run's notes directory, next to the review method.

A documented project rule always wins over a principle here. When you apply a principle, name it in the brief or the report together with the choice it changed. Cite only principles you read in this file during this run.

## Model the Domain

**When:** stateful logic, code that branches a lot, or code that repeats a shape assumption across files.

Encode the domain in a structure instead of scattered conditionals: a state machine instead of booleans that must stay in sync, a typed model instead of loose parameters, a table, map or registry instead of branching spread across files, a module that owns one body of domain knowledge instead of phase-named modules such as load, validate and save. Don't force an abstraction when the current shape is clear, local and unlikely to grow.

**You skipped it when** a new feature grows an existing if/else chain by one more branch, or adds a second flag that must stay in sync with the first.

## Boundary Discipline

**When:** wiring validation, error handling, config, external APIs or framework adapters.

Validate and parse at system boundaries (CLI args, config files, network input, external APIs) into domain types. Inside the system, trust the types and don't re-validate. Keep business logic in pure functions that the shell just calls. Don't expose transport, storage or framework types through the public surface. Errors propagate with their cause; never turn an I/O failure into a business result.

**The test:** is this data crossing a boundary right now? If not, the check is redundant.

## Subtract Before You Add

**When:** sizing a diff, refactoring, or tempted to add a layer, option or guard.

Remove dead weight first, then build on the simpler base. Make the smallest change that solves the problem. Put a repeated decision behind one source of truth. Design for observed use, not speculative edge cases: no validators, parsers, hooks or parameters the requirement doesn't need. When a unit of work repeats across many places, do the first one by hand, then write a script that does the rest and can be rerun to check them.

## Minimize Reader Load

**When:** shaping or reviewing code that is hard to trace.

Count two things: layers between a question and its answer, and hidden or mutable state the reader must hold. Inline wrappers with one caller and adapters with one implementation. Prefer returns over mutation, locals over fields, fields over module state. Name an invariant once, at the boundary.

**The test:** can a new reader answer "where does X come from?" and "what can change X?" in under 30 seconds?

## Make Operations Idempotent

**When:** commands, scripts, lifecycle steps or loops that may crash, be retried or be resumed.

Derive each step from the state that exists, not from what the previous run meant to do: read the current state, compare it to the goal, apply only the difference. Anything a run leaves behind (a lock, a temp file, a half-written record, a claimed job) must be recognisable as stale by the next run. Write to a temp path and rename into place.

**The test:** what happens if this runs twice, or if the previous run stopped at any point? If the answer depends on what was left behind, add a reconciliation step.

## Explain the Number

**When:** before measuring, and before reporting or acting on a number (a speedup, a latency, an eval score, a pass rate).

Write down beforehand which result would change a decision. Name what bounds the number (a resource, a lock, the load generator) from a profile or counters, not from reading code. List what else the number could be measuring (errors, skipped or cached work, code that never ran, noise, a sample too small) and rule each out. Keep the run count, the spread and the limiter with the number. When the spread between runs is larger than the effect, there is no result.

---

Adapted from [backnotprop/pstack](https://github.com/backnotprop/pstack) principle skills, MIT License.

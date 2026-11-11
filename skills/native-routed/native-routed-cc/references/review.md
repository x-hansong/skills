# Review method

The reviewer follows this. The orchestrator copies the file into the run's notes directory and the brief points to that copy, together with the baseline, the candidate (a commit or branch), the Spec source and the project's standards files.

The review is read-only and runs on two axes, reported separately:

- **Standards**: does the change follow the project's documented coding standards?
- **Spec**: does the change do what the requirement asked for?

A change can pass one and fail the other: clean code that builds the wrong thing, or the right thing built against the project's conventions. Reporting them apart stops one from masking the other.

## 1. Pin the diff

Read the change as `git diff <baseline>...<candidate>` (three dots, against the merge base) and list its commits with `git log --oneline <baseline>..<candidate>`. Resolve both refs with `git rev-parse` first. A bad ref or an empty diff is the first thing to report; stop there.

## 2. Spec source

Use the source in the brief: the spec and tickets, or, without them, the confirmed requirement and the scope notes. When the brief names none, look for issue references in the commit messages and spec files under `docs/`, `specs/` or `.scratch/` matching the branch. When nothing is found, the Spec axis reports "no spec available"; don't invent one.

## 3. Standards sources

Every file in the repo that documents how code is written: `AGENTS.md`, `CLAUDE.md`, `CODING_STANDARDS.md` and `CONTRIBUTING.md` when they exist, and any style or architecture docs they point to. Skip what linters and formatters already enforce.

On top of them, apply this smell baseline (Fowler, _Refactoring_, ch. 3). A documented project rule always wins: where it endorses something below, drop the smell. Every smell is a judgement call ("possible Feature Envy"), never a hard violation.

- **Mysterious Name**: a name that doesn't say what it does or holds. Rename it.
- **Duplicated Code**: the same logic shape in more than one hunk or file. Extract it.
- **Feature Envy**: a function reaching into another object's data more than its own. Move it to that data.
- **Data Clumps**: the same fields or parameters travelling together. Bundle them into a type.
- **Primitive Obsession**: a primitive standing in for a domain concept. Give the concept a type.
- **Repeated Switches**: the same `switch` or `if` cascade on the same type in several places. Use polymorphism or one shared map.
- **Shotgun Surgery**: one logical change scattered over many files. Gather what changes together.
- **Divergent Change**: one module edited for several unrelated reasons. Split it.
- **Speculative Generality**: abstractions, parameters or hooks the spec doesn't need. Inline them back.
- **Message Chains**: long `a.b().c().d()` navigation the caller shouldn't depend on. Hide the walk behind one method.
- **Middle Man**: a class or function that mostly delegates. Call the real target.
- **Refused Bequest**: a subtype that ignores most of what it inherits. Use composition.

Then apply the design principles copy in the notes (`principles.md`) as a second baseline, with the same rules: a documented project rule wins, every finding is a judgement call at P3, and it names the principle and quotes the hunk. A principle never raises a finding above P3; a defect it points to is ranked on its own evidence.

## 4. Review each axis

Do the two passes one after the other and keep their notes apart.

- **Standards**: per file or hunk, every breach of a documented rule (cite the file and the rule) and every baseline smell (name it, quote the hunk). Mark which findings are hard breaches and which are judgement calls.
- **Spec**: requirements missing or partial; behaviour nobody asked for (scope creep); requirements that look implemented but are implemented wrong. Quote the spec line for each.

## 5. Prove each finding

A defect finding counts only when a run shows it. For every behaviour or Spec finding you would rank P0–P2, run something against the real code that shows the wrong behaviour: an existing test, a new test or repro script, or a plain command. Keep the review read-only: put new tests and scripts in the notes directory or a temp directory, never in the repo, and point them at the candidate. Record the exact command, the output it printed and the output the requirement needs.

- A breach of a hard documented rule (Standards P2) is proven by quoting the rule and the hunk; it needs no run.
- A defect you suspect but could not show with a run goes under **Unproven**, with what you tried. It gets no severity and is never fixed automatically.
- Leave out risks that matter only after some future change.
- No findings is a valid result.

## 6. Severity

| Severity | Meaning |
| --- | --- |
| **P0** | Blocks merge now: security hole, data loss or cross-user leak, main flow unusable. |
| **P1** | Definite functional defect: a wrong result on normal input. |
| **P2** | A real defect on specific inputs or edges, or a breach of a hard documented rule (security, logging of sensitive data, error contract). |
| **P3** | Works; maintainability, style or a judgement-call smell. Never blocks merge. |

Every baseline smell is P3. A documented-rule breach is P2 only when the rule is hard; otherwise P3.

## 7. Report

Under `## Standards` and `## Spec`, each finding with its severity, location and evidence, under 400 words per axis; a P0–P2 behaviour or Spec finding's evidence is its command, the output it printed and the output required. Then `## Unproven`, one line each. Don't merge or rerank findings across axes. End with one line: the number of findings per axis and the worst one within each axis.

---

Adapted from [mattpocock/skills](https://github.com/mattpocock/skills), MIT License.

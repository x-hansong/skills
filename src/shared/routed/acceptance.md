# Acceptance

The orchestrator applies this on every finish notification.

Don't accept an agent's summary on its own word, and don't verify by reading source yourself. Source reading belongs to the reviewer, in the cases listed in [when the reviewer runs](reviewer-use.md).

## On every finish

- Check that the brief's deliverable exists: the commits with their SHAs, or the file at the named path. When it doesn't, the agent is still working, whatever its reply says.
- Rerun the commands the brief names, and read the files the agent produced: the test log's exit code, the receipt, the report. Read a diff only through `--stat` against the brief's file scope. Read a diff in full only when it fits on one screen.
- Read the report's verdict block, then the evidence it indexes. For exploration and research, check each conclusion against the sources and file locations the report quotes, and the acceptance checks and open questions it lists; a pure research task is accepted on its deliverable. A conclusion the evidence does not support, or that the user or another report disputes, goes to the reviewer as a verifier case.
- For implementation, the review is the check that the diff matches the brief and that the acceptance checks hold on the committed head. A review verdict covers one head SHA; a later commit needs a new verdict.
- When the deliverable is a set of judgments (scores, verdicts, labels, classifications), a summary count is inconclusive on its own. Read the per-item output yourself (it is an artifact, not source): for every item whose judgment changed against the baseline or disagrees with a reference label, read the stated reason and the material it cites. A reason that contradicts its own verdict, or cites material outside the judged input, is a finding. A judgment that cites nothing (an absent verdict) is checked against the full input the judge was given. For each wrong judgment, decide whether the judge erred or the item's own wording led it there, such as a prohibition or a "not required" clause listed as a required element; fix the item in that case, since rewording the judge prompt around a flawed item rarely holds. When the project keeps a labelled reference set, compare against it and read only the disagreements.

Send back work that drifts past the brief: keep only what blocks this task and record the rest in the notes as follow-ups.

## Worktree cleanup

Clean up the worktrees this task created once their branches are merged or abandoned. Before removing one, list what `git status --ignored` shows there that this task produced (run outputs, baselines, private data) and copy it before removal: outputs a tool in the main checkout reads (run and trial artifacts) go to the same relative path in the main checkout without overwriting, and that tool must then list them; private baselines and logs go to the notes directory. Removing a worktree deletes its ignored files too.

## Conclusions for the next agent

Before reporting, move every conclusion this run gave the user in answer to a question (why a limit exists, what was measured and what was not) into a document the project's entry file already routes to: a short statement beside the thing it explains, and the evidence in the project's verification records. Notes outside the repository are not where the next agent looks. When the repository keeps no such place, say so in the report instead of leaving the conclusion only in the notes.

## Verdicts and counts

Give every acceptance check one verdict: **verified** (you saw the evidence on the real artifact), **not verified** (the evidence shows it fails) or **inconclusive** (no evidence, or evidence from the wrong surface). Inconclusive is not a pass.

Every count you report (verdicts, cases, files) comes from a script run over the deliverables, and counts identities, not directories or files: a re-scored or copied artifact of a run is that same run, so deduplicate by the original run ID; a retry is a new run. Never sum agent reports by hand.

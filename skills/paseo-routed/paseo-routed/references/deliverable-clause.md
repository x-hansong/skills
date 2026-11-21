# Report deliverable clause

Paste the block below unchanged into every brief that asks for a report. Replace only `<REPORT>`.
Do not restate the limit in your own words: briefs that said "under ~400 lines" got reports of
20-60 KB, and reading them whole filled the orchestrator's context.

```
Deliverable: write the report to <REPORT>.md in the notes.
- The report is at most 8000 characters. Count characters, not lines: run `LC_ALL=C.UTF-8 wc -m <REPORT>.md`
  before you reply, and shorten it if the count is over.
- Open it with a verdict block of at most 15 lines: what you did or found, an index of the
  evidence (file path or command, one line each), open questions, and anything you did not verify.
- Put everything else in <REPORT>.detail.md beside it, with one `##` heading per claim the
  verdict block cites. The orchestrator reads a section with `grep -n '^## ' <REPORT>.detail.md`
  then `sed -n`; it opens the detail only where a claim is disputed.
- Reply done only after both files exist and `LC_ALL=C.UTF-8 wc -m <REPORT>.md` is 8000 or less.
```

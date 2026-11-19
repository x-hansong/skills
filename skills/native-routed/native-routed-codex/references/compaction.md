# After a context compaction

The orchestrator reads this when its context has just been compacted. A compaction keeps a summary and drops most of what you read, so the next move is a re-read unless you aim it.

- Name the next step from the summary and `progress.md`, then read only the files that step names.
- Before reopening a skill or reference, check whether its text is still in context. Open it only when the step you are about to do names it and its text is gone.
- Bring back a file's part, not the file: `grep -n '^#'` for its headings, then `sed -n` over the section the step uses. A report's `.detail.md` is read the same way.

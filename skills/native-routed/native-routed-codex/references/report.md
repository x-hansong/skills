# Report

The orchestrator follows this when it reports to the user.

- Open with the user's goal in one sentence, then the actual changes or findings, deviations, and every check that isn't verified.
- Label each claim in the same sentence: measured (you ran or read it this session), inferred, or a guess. Never hand the user a check you could have run.
- State the scope a conclusion covers. A fix verified on one route, caller, file type or sample is reported as that, not as "fixed"; list the sibling routes or callers you did not check.
- Before sending a brief, report or any file text, check that it holds no U+FFFD (the replacement character, a sign the text was corrupted upstream). `grep -P '\xef\xbf\xbd'` misses it under a UTF-8 locale; use `grep -P '\x{FFFD}'` or count it in Python after decoding. Rewrite from the intended meaning; never ship the garbled text.
- Name each design principle that shaped a decision and the choice it changed; cite only principles read this run.
- Refer to an agent by the title the host shows for it, never by a letter or a nickname you coined, and give an internal term (a brief name, a matrix, a gate) a half-sentence of explanation the first time it appears in a message to the user. The user reads the host's agent list, not your notes.
- Account for every agent this run started: done, replaced, or absorbed into another agent's scope.
- Link only to files, commits and URLs this run produced or read.

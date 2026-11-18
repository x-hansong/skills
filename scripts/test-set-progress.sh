#!/usr/bin/env bash
# Exercise set-progress.sh: label and heading sections, append vs replace, errors, the 40-line cap.
set -euo pipefail
cd "$(dirname "$0")/.."
dir=skills/paseo-routed/paseo-routed/scripts
init=$dir/init-notes.sh
script=$dir/set-progress.sh
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

expect() {
  local expected=$1 actual=0
  shift
  "$@" > "$tmp/output" 2>&1 || actual=$?
  if [ "$actual" -ne "$expected" ]; then
    printf 'FAIL: expected %s, got %s: %s\n' "$expected" "$actual" "$*" >&2
    cat "$tmp/output" >&2
    return 1
  fi
}
has() { grep -qxF -- "$1" "$tmp/n/progress.md" || { printf 'FAIL: missing line: %s\n' "$1" >&2; cat "$tmp/n/progress.md" >&2; return 1; }; }
lacks() { ! grep -qF -- "$1" "$tmp/n/progress.md" || { printf 'FAIL: unexpected: %s\n' "$1" >&2; cat "$tmp/n/progress.md" >&2; return 1; }; }

[ -x "$script" ] || { printf 'FAIL: missing executable %s\n' "$script" >&2; exit 1; }
"$init" --roster main --worker 'Builder (p/m)' --reviewer 'Critic (p/m)' "$tmp/n" > /dev/null

# Label sections: replace writes after the colon and is idempotent.
expect 0 "$script" "$tmp/n" --replace "Current step" "unit 2 of 4"
has "Current step: unit 2 of 4"
expect 0 "$script" "$tmp/n" --replace "Current step" "unit 3 of 4"
has "Current step: unit 3 of 4"
lacks "unit 2 of 4"
has "Verified:"

# A label can take extra lines too; they land under it, before the next label.
expect 0 "$script" "$tmp/n" --append Next "then review" "then deliver"
has "then review"
has "then deliver"
next_line=$(grep -n '^Next:' "$tmp/n/progress.md" | cut -d: -f1)
review_line=$(grep -n '^then review' "$tmp/n/progress.md" | cut -d: -f1)
gotchas_line=$(grep -n '^Key files and gotchas:' "$tmp/n/progress.md" | cut -d: -f1)
[ "$next_line" -lt "$review_line" ] && [ "$review_line" -lt "$gotchas_line" ] || { printf 'FAIL: appended label lines out of place\n' >&2; exit 1; }

# Heading sections: append keeps order, replace keeps the comment, other sections stay put.
expect 0 "$script" "$tmp/n" --append Decisions "use merge (orchestrator)"
expect 0 "$script" "$tmp/n" --append Decisions "keep tests (user 2026-01-01)"
has "use merge (orchestrator)"
has "keep tests (user 2026-01-01)"
expect 0 "$script" "$tmp/n" --append "Live resources" "agent-1 | worker | /w/a | worktree"
expect 0 "$script" "$tmp/n" --replace "Live resources" "agent-2 | worker | /w/b | worktree"
has "agent-2 | worker | /w/b | worktree"
lacks "agent-1"
grep -qF '<!-- full agent ID' "$tmp/n/progress.md"
grep -qxF '## Reviewed SHA' "$tmp/n/progress.md"
grep -qxF '## Open gates' "$tmp/n/progress.md"
# Decisions survive edits to a later section, and stay before it.
decisions=$(grep -n 'use merge' "$tmp/n/progress.md" | cut -d: -f1)
live=$(grep -n '^## Live resources' "$tmp/n/progress.md" | cut -d: -f1)
[ "$decisions" -lt "$live" ] || { printf 'FAIL: decisions moved after live resources\n' >&2; exit 1; }

# Standard input carries lines that are awkward to quote.
printf '%s\n' 'sha with "quotes" and | pipes' | "$script" "$tmp/n" --append "Open gates"
has 'sha with "quotes" and | pipes'

# Errors.
expect 1 "$script" "$tmp/n" --append Nope x
# An unknown section lists the valid ones; a label with its colon is unknown, not silently accepted.
for name in Intent "Current step" "Key files and gotchas" Decisions "Live resources" "Reviewed SHA" "Open gates"; do
  grep -qF -- "$name" "$tmp/output" || { printf 'FAIL: error output omits section "%s"\n' "$name" >&2; cat "$tmp/output" >&2; exit 1; }
done
expect 1 "$script" "$tmp/n" --append "Intent:" x
grep -qF 'without its colon' "$tmp/output" || { printf 'FAIL: colon hint missing\n' >&2; cat "$tmp/output" >&2; exit 1; }
expect 1 "$script" "$tmp/missing" --append Decisions x
expect 2 "$script" "$tmp/n" --bogus Decisions x
expect 2 "$script" "$tmp/n"

# The 40-line cap refuses and leaves the file as it was.
before=$(cksum < "$tmp/n/progress.md")
many=$(seq 1 40 | sed 's/^/line /')
expect 1 "$script" "$tmp/n" --append Decisions "$many"
[ "$before" = "$(cksum < "$tmp/n/progress.md")" ] || { printf 'FAIL: file changed after a refused edit\n' >&2; exit 1; }

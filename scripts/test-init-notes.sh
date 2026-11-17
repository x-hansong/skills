#!/usr/bin/env bash
# Exercise init-notes.sh: files created, refusal to overwrite, usage errors.
set -euo pipefail
cd "$(dirname "$0")/.."
script=skills/paseo-routed/paseo-routed/scripts/init-notes.sh
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

[ -x "$script" ] || { printf 'FAIL: missing executable %s\n' "$script" >&2; exit 1; }

args=(--roster main --worker 'Builder (p/m)' --reviewer 'Critic (p/m)')
expect 0 "$script" "${args[@]}" "$tmp/notes dir/topic"
[ "$(cat "$tmp/output")" = "$tmp/notes dir/topic" ]
for file in scope.md progress.md log.md tests.md review.md principles.md; do
  [ -f "$tmp/notes dir/topic/$file" ] || { printf 'FAIL: %s not created\n' "$file" >&2; exit 1; }
done
grep -qF 'Roster: main' "$tmp/notes dir/topic/scope.md"
grep -qF 'Worker: Builder (p/m)' "$tmp/notes dir/topic/scope.md"
grep -qF '## Live resources' "$tmp/notes dir/topic/progress.md"
grep -qF '## Reviewed SHA' "$tmp/notes dir/topic/progress.md"
grep -qF '## Open gates' "$tmp/notes dir/topic/progress.md"
cmp skills/paseo-routed/paseo-routed/references/review.md "$tmp/notes dir/topic/review.md"

# A second run must not clobber existing notes.
printf 'kept\n' >> "$tmp/notes dir/topic/progress.md"
expect 1 "$script" "${args[@]}" "$tmp/notes dir/topic"
grep -qF 'kept' "$tmp/notes dir/topic/progress.md"

expect 2 "$script" "${args[@]}"
expect 2 "$script" --roster main "$tmp/x"
expect 2 "$script" "${args[@]}" "$tmp/a" "$tmp/b"
expect 2 "$script" "${args[@]}" --bogus "$tmp/a"
[ ! -e "$tmp/a" ] && [ ! -e "$tmp/x" ]

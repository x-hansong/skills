#!/usr/bin/env bash
# Create the shared notes directory for a routed run.
# 0 = created, 1 = notes already exist (resume instead), 2 = usage.
set -eu

usage() {
  printf '%s\n' 'Usage: init-notes.sh --roster NAME --worker PROFILE --reviewer PROFILE NOTES_DIR/TOPIC' >&2
  printf '%s\n' '  PROFILE is the profile name with its model, e.g. "Builder (provider/model)".' >&2
  exit 2
}

roster=
worker=
reviewer=
target=
while [ "$#" -gt 0 ]; do
  case "$1" in
    --roster) [ "$#" -ge 2 ] || usage; roster=$2; shift 2 ;;
    --worker) [ "$#" -ge 2 ] || usage; worker=$2; shift 2 ;;
    --reviewer) [ "$#" -ge 2 ] || usage; reviewer=$2; shift 2 ;;
    -h|--help) usage ;;
    -*) usage ;;
    *) [ -z "$target" ] || usage; target=$1; shift ;;
  esac
done
{ [ -n "$roster" ] && [ -n "$worker" ] && [ -n "$reviewer" ] && [ -n "$target" ]; } || usage

# A quoted "~/..." arrives unexpanded.
case "$target" in "~"/*) target="$HOME/${target#\~/}" ;; esac

here=$(cd "$(dirname "$0")" && pwd)
refs="$here/../references"
for file in tests.md review.md principles.md; do
  [ -f "$refs/$file" ] || { printf 'init-notes.sh: missing %s\n' "$refs/$file" >&2; exit 1; }
done

if [ -e "$target/scope.md" ] || [ -e "$target/progress.md" ]; then
  printf 'init-notes.sh: %s already has notes; resume from its progress.md instead of re-initialising\n' "$target" >&2
  exit 1
fi

mkdir -p -- "$target"
cp -- "$refs/tests.md" "$refs/review.md" "$refs/principles.md" "$target/"
: >> "$target/log.md"

cat > "$target/scope.md" <<EOF
Keywords: <features, samples, modules and repositories this task touches>

# Scope

Created: $(date -u +%Y-%m-%dT%H:%MZ)
Roster: $roster
Worker: $worker
Reviewer: $reviewer

Goal:
Done-condition (name the surface the user checks):
Out of scope:
EOF

cat > "$target/progress.md" <<'EOF'
# Progress

Rewritten by the orchestrator at every unit boundary; keep under 40 lines. Agents append to log.md.

Intent:
Current step:
Verified:
Next:
Key files and gotchas:

## Decisions
<!-- one line each, tagged "user (<message timestamp>)" or "orchestrator" -->

## Live resources
<!-- full agent ID | role | workspace path | isolation (worktree or local) -->

## Reviewed SHA
<!-- repository | reviewed SHA | verdict; delivery needs this to equal the HEAD to be pushed -->

## Open gates
<!-- project delivery gates a brief deferred; stay listed until met -->
EOF

printf '%s\n' "$target"

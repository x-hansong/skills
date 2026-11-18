#!/usr/bin/env bash
# Exercise live-agents.sh with a fake `paseo` on PATH: running, stopped and missing agents, empty list, failures.
set -euo pipefail
cd "$(dirname "$0")/.."
root=$PWD
dir=skills/paseo-routed/paseo-routed/scripts
init=$root/$dir/init-notes.sh
script=$root/$dir/live-agents.sh
set_progress=$root/$dir/set-progress.sh
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

a=11111111-1111-4111-8111-111111111111
b=22222222-2222-4222-8222-222222222222
c=33333333-3333-4333-8333-333333333333

mkdir "$tmp/bin"
cat > "$tmp/bin/paseo" <<'FAKE'
#!/usr/bin/env bash
[ "$*" = "ls -a -g --json" ] || { echo "fake paseo: unexpected args: $*" >&2; exit 64; }
[ -z "${FAKE_PASEO_FAIL:-}" ] || { echo "daemon unreachable" >&2; exit 1; }
cat "$FAKE_PASEO_JSON"
FAKE
chmod +x "$tmp/bin/paseo"
export PATH="$tmp/bin:$PATH" FAKE_PASEO_JSON="$tmp/ls.json"

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
shows() { grep -qF -- "$1" "$tmp/output" || { printf 'FAIL: output lacks: %s\n' "$1" >&2; cat "$tmp/output" >&2; return 1; }; }

[ -x "$script" ] || { printf 'FAIL: missing executable %s\n' "$script" >&2; exit 1; }
"$init" --roster main --worker 'Builder (p/m)' --reviewer 'Critic (p/m)' "$tmp/n" > /dev/null

# Nothing listed: exit 0 without calling paseo.
FAKE_PASEO_FAIL=1 expect 0 "$script" "$tmp/n"
shows "no live agents"

"$set_progress" "$tmp/n" --replace "Live resources" \
  "$a | worker | /w/a | worktree" \
  "$b | reviewer | /w/b | local" \
  "main checkout at /srv/x, not an agent" > /dev/null
cat > "$tmp/ls.json" <<JSON
[{"id":"$a","shortId":"11111111","name":"Builder","status":"running"},
 {"id":"$b","shortId":"22222222","name":"Critic","status":"running"},
 {"id":"$c","shortId":"33333333","name":"Other","status":"idle"}]
JSON
expect 0 "$script" "$tmp/n"
shows "all 2 live agents are running"

# A listed agent that finished is reported and exits 3; an unlisted idle agent is ignored.
sed -i "s/\"id\":\"$b\",\"shortId\":\"22222222\",\"name\":\"Critic\",\"status\":\"running\"/\"id\":\"$b\",\"shortId\":\"22222222\",\"name\":\"Critic\",\"status\":\"idle\"/" "$tmp/ls.json"
expect 3 "$script" "$tmp/n"
shows "idle"
shows "$b Critic"
shows "1 of 2 live agents are not running"

# error and closed count as stopped; an ID absent from the daemon is reported as missing.
printf '[{"id":"%s","name":"Builder","status":"error"}]\n' "$a" > "$tmp/ls.json"
expect 3 "$script" "$tmp/n"
shows "error"
shows "missing"
shows "2 of 2 live agents are not running"
printf '[{"id":"%s","name":"Builder","status":"closed"},{"id":"%s","name":"Critic","status":"initializing"}]\n' "$a" "$b" > "$tmp/ls.json"
expect 3 "$script" "$tmp/n"
shows "closed"
shows "1 of 2 live agents are not running"

# Entries in other sections never count as live agents.
"$set_progress" "$tmp/n" --replace "Live resources" "$a | worker | /w/a | worktree" > /dev/null
"$set_progress" "$tmp/n" --append Decisions "$b was a reviewer (orchestrator)" > /dev/null
printf '[{"id":"%s","name":"Builder","status":"running"}]\n' "$a" > "$tmp/ls.json"
expect 0 "$script" "$tmp/n"
shows "all 1 live agents are running"

# Failures are loud.
FAKE_PASEO_FAIL=1 expect 1 "$script" "$tmp/n"
shows "paseo ls"
expect 1 "$script" "$tmp/missing"
expect 2 "$script"
expect 2 "$script" --help
expect 2 "$script" "$tmp/n" extra
printf '{"not":"a list"}\n' > "$tmp/ls.json"
expect 1 "$script" "$tmp/n"

printf 'live-agents tests passed\n'

#!/usr/bin/env bash
# Exercise the installed script interface for every routed host.
set -euo pipefail
cd "$(dirname "$0")/.."
tmp=$(mktemp -d)
job=
trap 'if [ -n "$job" ]; then kill "$job" 2>/dev/null || :; wait "$job" 2>/dev/null || :; fi; rm -rf "$tmp"' EXIT

expect() {
  local expected=$1 actual=0
  shift
  "$@" > "$tmp/output" 2>&1 || actual=$?
  if [ "$actual" -ne "$expected" ]; then
    printf 'FAIL: expected %s, got %s: %s\n' "$expected" "$actual" "$*" >&2
    return 1
  fi
}

for script in skills/paseo-routed/paseo-routed/scripts/wait-job.sh \
  skills/native-routed/native-routed-{cc,codex}/scripts/wait-job.sh; do
  [ -x "$script" ] || { printf 'FAIL: missing executable %s\n' "$script" >&2; exit 1; }
  sleep 30 &
  job=$!
  printf 'one\ntwo\nthree\nfour\nfive\nsix\n' > "$tmp/job log"
  expect 75 "$script" --max 1 --interval 60 --log "$tmp/job log" --pid "$job"
  printf 'two\nthree\nfour\nfive\nsix\n' > "$tmp/expected"
  cmp "$tmp/expected" "$tmp/output"
  kill "$job"
  wait "$job" 2>/dev/null || :
  expect 0 "$script" --max 1 --pid "$job"
  job=
  expect 0 "$script" --max 2 --interval 1 -- test 'literal; argument' = 'literal; argument'
  expect 75 "$script" --max 1 --interval 1 -- false
  expect 75 "$script" --max 1 -- sleep 30
  expect 2 "$script" --max 571 -- true
  expect 2 "$script" --max 0 -- true
  expect 2 "$script" --interval 0 -- true
  expect 2 "$script" --pid 0
  expect 2 "$script" --pid -1
  expect 2 "$script" --pid not-a-pid
  expect 2 "$script" --max nope -- true
  expect 2 "$script" --max
  expect 2 "$script" --
  expect 2 "$script"
  expect 2 "$script" --pid 1 -- true
  expect 2 "$script" --log "$tmp/job log" --unknown
  tail -n 5 "$tmp/output" > "$tmp/log-tail"
  cmp "$tmp/expected" "$tmp/log-tail"
done
printf 'OK: wait-job tests passed\n'

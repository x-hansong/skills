#!/usr/bin/env bash
# Wait for a job in bounded chunks; 0 = finished, 75 = still running, 2 = usage.
set -u
max=540
interval=60
log=
pid=
check_pid=

cleanup_check() {
  if [ -n "$check_pid" ]; then
    kill -KILL -- "-$check_pid" 2>/dev/null || :
    wait "$check_pid" 2>/dev/null || :
    check_pid=
  fi
}
finish() {
  cleanup_check
  if [ -n "$log" ]; then tail -n 5 -- "$log" || :; fi
  exit "$1"
}
usage() {
  printf '%s\n' 'Usage: wait-job.sh [--max SECONDS] [--interval SECONDS] [--log FILE] (--pid PID | -- CHECK_CMD...)' >&2
  finish 2
}
positive_integer() {
  case "$1" in ''|*[!0-9]*|0*) return 1 ;; esac
  # Bound length before shell arithmetic to avoid overflow.
  [ "${#1}" -le 9 ]
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --max|--interval|--log|--pid)
      [ "$#" -ge 2 ] || usage
      case "$1" in
        --max) max=$2 ;;
        --interval) interval=$2 ;;
        --log) log=$2 ;;
        --pid) [ -z "$pid" ] || usage; pid=$2 ;;
      esac
      shift 2
      ;;
    --) shift; [ "$#" -gt 0 ] && [ -z "$pid" ] || usage; break ;;
    *) usage ;;
  esac
done
positive_integer "$max" && [ "$max" -le 570 ] || usage
positive_integer "$interval" || usage
if [ -n "$pid" ]; then
  positive_integer "$pid" || usage
else
  [ "$#" -gt 0 ] || usage
fi
# Give each check its own process group, including on macOS Bash 3.2.
[ -n "$pid" ] || set -m
trap 'finish 75' HUP INT TERM
SECONDS=0
while :; do
  if [ -n "$pid" ]; then
    kill -0 "$pid" 2>/dev/null || finish 0
  else
    # COSEC: preserve argv literally; never evaluate a command string.
    "$@" &
    check_pid=$!
    while kill -0 "$check_pid" 2>/dev/null; do
      [ "$SECONDS" -lt "$max" ] || finish 75
      sleep 1
    done
    result=0
    wait "$check_pid" || result=$?
    cleanup_check
    [ "$result" -ne 0 ] || finish 0
  fi
  remaining=$((max - SECONDS))
  [ "$remaining" -gt 0 ] || finish 75
  delay=$interval
  [ "$delay" -le "$remaining" ] || delay=$remaining
  sleep "$delay"
done

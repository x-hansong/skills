#!/usr/bin/env bash
# Print the Paseo status of every agent listed under "## Live resources" in progress.md.
# Exit 0: every listed agent is still running, or none is listed. Exit 3: at least one is not running.
# Exit 1: progress.md is missing or `paseo ls` failed. Exit 2: usage.
set -eu

[ "$#" -eq 1 ] && [ "${1#-}" = "$1" ] || { printf '%s\n' 'Usage: live-agents.sh NOTES_DIR' >&2; exit 2; }
dir=$1
case "$dir" in "~"/*) dir="$HOME/${dir#\~/}" ;; esac
file="$dir/progress.md"
[ -f "$file" ] || { printf 'live-agents.sh: %s not found\n' "$file" >&2; exit 1; }

# A line counts when it starts with a full agent ID. No match is a valid state (nothing live);
# any other grep failure stops the script.
ids=$(awk '/^## / { live = ($0 == "## Live resources"); next } live' "$file" \
  | grep -Eo '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' || [ "$?" -eq 1 ])
if [ -z "$ids" ]; then
  printf 'no live agents listed in %s\n' "$file"
  exit 0
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
paseo ls -a -g --json > "$tmp" || { printf 'live-agents.sh: `paseo ls` failed\n' >&2; exit 1; }

# running and initializing mean the agent is at work. idle, error, closed or absent from the list
# mean its turn is over, so its finish notification is due and may have been read past.
printf '%s\n' "$ids" | node -e '
const fs = require("fs");
const ids = fs.readFileSync(0, "utf8").split("\n").filter(Boolean);
const byId = new Map(JSON.parse(fs.readFileSync(process.argv[1], "utf8")).map((a) => [a.id, a]));
let stopped = 0;
for (const id of ids) {
  const agent = byId.get(id);
  const status = agent ? agent.status : "missing";
  if (status !== "running" && status !== "initializing") stopped++;
  console.log(`${status.padEnd(12)} ${id} ${agent ? agent.name : ""}`.trimEnd());
}
console.log(stopped === 0 ? `all ${ids.length} live agents are running` : `${stopped} of ${ids.length} live agents are not running`);
process.exitCode = stopped === 0 ? 0 : 3;
' "$tmp"

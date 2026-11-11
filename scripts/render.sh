#!/usr/bin/env bash
# Render twin skills from src/. Edit src/, never the rendered copies under skills/.
#
#   src/native-routed/<base>/<file>.tmpl -> skills/native-routed/<base>-<host>/<file>, host in cc, codex
#   src/shared/<file>                    -> every path listed for it in SHARED below
#
# In a template, `{host}` becomes the host, and lines between `%% <host>` and `%% end` are kept only for that host.
# `render.sh --check` renders into a temp dir and fails if skills/ differs.
set -euo pipefail
cd "$(dirname "$0")/.."

hosts=(cc codex)
SHARED=(
  "routed/review.md skills/paseo-routed/paseo-routed/references/review.md"
  "routed/review.md skills/native-routed/native-routed-cc/references/review.md"
  "routed/review.md skills/native-routed/native-routed-codex/references/review.md"
  "routed/tests.md skills/paseo-routed/paseo-routed/references/tests.md"
  "routed/tests.md skills/native-routed/native-routed-cc/references/tests.md"
  "routed/tests.md skills/native-routed/native-routed-codex/references/tests.md"
  "routed/principles.md skills/paseo-routed/paseo-routed/references/principles.md"
  "routed/principles.md skills/native-routed/native-routed-cc/references/principles.md"
  "routed/principles.md skills/native-routed/native-routed-codex/references/principles.md"
)

render_template() { # host template
  awk -v host="$1" '
    /^%% (cc|codex)$/ { block = $2; next }
    /^%% end$/        { block = ""; next }
    block == "" || block == host { gsub(/\{host\}/, host); print }
  ' "$2"
}

render_into() { # root
  local root=$1 tmpl rel base file host
  while IFS= read -r tmpl; do
    rel=${tmpl#src/native-routed/}
    base=${rel%%/*}
    file=${rel#*/}
    for host in "${hosts[@]}"; do
      mkdir -p "$(dirname "$root/skills/native-routed/$base-$host/${file%.tmpl}")"
      render_template "$host" "$tmpl" > "$root/skills/native-routed/$base-$host/${file%.tmpl}"
    done
  done < <(find src/native-routed -type f -name '*.tmpl' | sort)
  local entry
  for entry in "${SHARED[@]}"; do
    read -r rel file <<< "$entry"
    mkdir -p "$(dirname "$root/$file")"
    cp "src/shared/$rel" "$root/$file"
  done
}

if [ "${1:-}" = "--check" ]; then
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  render_into "$tmp"
  status=0
  diff -r "$tmp/skills/native-routed" skills/native-routed || status=1
  for entry in "${SHARED[@]}"; do
    read -r rel file <<< "$entry"
    diff "$tmp/$file" "$file" || status=1
  done
  [ "$status" -eq 0 ] || echo "FAIL: rendered skills differ from src/; edit src/ and run scripts/render.sh" >&2
  exit "$status"
fi

render_into .
echo "Rendered skills from src/"

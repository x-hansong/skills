#!/usr/bin/env bash
# Edit one section of progress.md without rewriting the file by hand.
# 0 = done, 1 = file or section not found or the result is too long, 2 = usage.
set -eu

usage() {
  printf '%s\n' 'Usage: set-progress.sh NOTES_DIR (--append|--replace) SECTION [LINE...]' >&2
  printf '%s\n' '  SECTION is a "## " heading ("Decisions", "Live resources", "Reviewed SHA", "Open gates")' >&2
  printf '%s\n' '  or a label from the top block: Intent, "Current step", Verified, Next, "Key files and gotchas".' >&2
  printf '%s\n' '  --append adds LINEs after the last line of the section; --replace swaps its content for LINEs.' >&2
  printf '%s\n' '  A heading section keeps its <!-- comment --> line. With no LINE arguments, LINEs come from stdin.' >&2
  exit 2
}

[ "$#" -ge 3 ] || usage
dir=$1
mode=${2#--}
section=$3
shift 3
case "$mode" in append|replace) ;; *) usage ;; esac
case "$dir" in "~"/*) dir="$HOME/${dir#\~/}" ;; esac
file="$dir/progress.md"
[ -f "$file" ] || { printf 'set-progress.sh: %s not found\n' "$file" >&2; exit 1; }

new=$(mktemp)
out=$(mktemp)
trap 'rm -f "$new" "$out"' EXIT
if [ "$#" -gt 0 ]; then printf '%s\n' "$@" > "$new"; else cat > "$new"; fi

# Both kinds of section end where the next structure starts: the next "## " heading or, for the
# top block, the next "Label:" line. Blank lines before that boundary stay as separators.
awk -v section="$section" -v mode="$mode" -v newfile="$new" '
  BEGIN {
    while ((getline line < newfile) > 0) add[++count] = line
    close(newfile)
    state = "before"; pending = 0
  }
  function flush_pending(   i) { for (i = 1; i <= pending; i++) print held[i]; pending = 0 }
  function emit(   i) { for (i = 1; i <= count; i++) print add[i] }
  function close_section() {
    if (state != "in") return
    if (kind == "heading" || mode == "append") emit()   # replace on a label wrote its content inline
    flush_pending()
    state = "after"
  }
  {
    heading = ($0 ~ /^## /)
    label = (!heading && $0 ~ /^[A-Za-z][A-Za-z ]*:/)
    if (state == "in" && (heading || label)) close_section()

    if (state == "before" && $0 == "## " section) {
      print; state = "in"; kind = "heading"; found = 1; next
    }
    if (state == "before" && label && index($0, section ":") == 1) {
      found = 1; kind = "label"; state = "in"
      if (mode == "replace") {
        printf "%s:", section
        if (count > 0) printf " %s", add[1]
        print ""
        for (i = 2; i <= count; i++) print add[i]
      } else print
      next
    }
    if (state == "in") {
      if (kind == "label" && mode == "replace") next   # old continuation lines dropped
      if ($0 ~ /^<!--/) { print; next }                # keep the heading comment
      if ($0 == "") { held[++pending] = $0; next }     # trailing blanks stay after the new content
      flush_pending()
      if (mode == "replace") next                      # old body line dropped
      print; next
    }
    print
  }
  END {
    close_section()
    if (!found) exit 3
  }
' "$file" > "$out" || {
  rc=$?
  if [ "$rc" -eq 3 ]; then
    printf 'set-progress.sh: no section "%s" in %s\n' "$section" "$file" >&2
    # Same boundaries the awk script uses: "## " headings and "Label:" lines. Labels are named without the colon.
    names=$({ grep -E '^[A-Za-z][A-Za-z ]*:' "$file" | sed 's/:.*//'; sed -n 's/^## //p' "$file"; } | paste -sd '|' - | sed 's/|/, /g')
    printf 'set-progress.sh: sections in this file: %s (give a label without its colon)\n' "$names" >&2
    exit 1
  fi
  exit "$rc"
}

if [ "$(wc -l < "$out")" -gt 40 ]; then
  printf 'set-progress.sh: progress.md would be %s lines; keep it under 40 and trim before adding more\n' "$(wc -l < "$out")" >&2
  exit 1
fi
cat "$out" > "$file"

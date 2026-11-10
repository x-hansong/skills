#!/usr/bin/env bash
# Lint skills: frontmatter, cross-skill paths, and anything that looks private.
set -euo pipefail
cd "$(dirname "$0")/.."

status=0
fail() { echo "FAIL: $*" >&2; status=1; }

while IFS= read -r skill_md; do
  dir=$(basename "$(dirname "$skill_md")")
  frontmatter=$(awk 'NR==1 && $0=="---" {inside=1; next} inside && $0=="---" {exit} inside {print}' "$skill_md")
  [ -n "$frontmatter" ] || { fail "$skill_md: missing frontmatter"; continue; }

  name=$(printf '%s\n' "$frontmatter" | sed -n 's/^name: *//p' | tr -d '"')
  [ "$name" = "$dir" ] || fail "$skill_md: name '$name' does not match directory '$dir'"
  printf '%s' "$name" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$' || fail "$skill_md: invalid name '$name'"

  description=$(printf '%s\n' "$frontmatter" | sed -n 's/^description: *//p' | sed 's/^"//; s/"$//')
  [ -n "$description" ] || fail "$skill_md: missing description"
  [ "${#description}" -le 1024 ] || fail "$skill_md: description is ${#description} chars (max 1024)"

  if printf '%s\n' "$frontmatter" | grep -q '^disable-model-invocation: true'; then
    yaml="$(dirname "$skill_md")/agents/openai.yaml"
    grep -q 'allow_implicit_invocation: false' "$yaml" 2>/dev/null \
      || fail "$skill_md: manual-only skill needs policy.allow_implicit_invocation: false in agents/openai.yaml"
  fi
done < <(find skills -name SKILL.md | sort)

# Group directories must not contain a SKILL.md of their own.
for group in skills/*/; do
  [ ! -f "${group}SKILL.md" ] || fail "${group}SKILL.md shadows the skills below it"
done

# Cross-skill install paths and private values.
patterns=(
  '~/\.(agents|claude|codex)/skills/[a-z]'   # install path to a named skill
  '/Users/[A-Za-z]'                          # macOS home paths
  '/home/[a-z]'                              # Linux home paths
  '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b'          # IPv4 addresses
  'srv_[A-Za-z0-9]{6,}'                      # Paseo server ids
  'agent_profile_[a-z0-9]{6,}_'              # real Paseo profile ids
  '(sk|ghp|gho|xox[bp])[-_][A-Za-z0-9]{16,}' # common token shapes
  'BEGIN [A-Z ]*PRIVATE KEY'
)
for pattern in "${patterns[@]}"; do
  if matches=$(grep -rEn --exclude-dir=.git --exclude=check.sh -- "$pattern" . 2>/dev/null); then
    fail "forbidden pattern '$pattern':"$'\n'"$matches"
  fi
done

# Skills depend only on this repo and Paseo: no loading other skills, no reading another skill's SKILL.md.
external='implement|implement-spec|tdd|code-review|to-spec|to-tickets|grilling'
if matches=$(grep -rEin --include='*.md' -e "(load|loads|use|uses|call|calls) (the )?\`($external)\`( skill)?" \
    -e "open its \`SKILL\.md\`" -e "SKILL\.md\` (path|from)" skills 2>/dev/null); then
  fail "dependency on an external skill (inline the method in a reference instead):"$'\n'"$matches"
fi

# Extra private terms, one regex per line, kept out of the repo (e.g. your own hostnames or profile names).
if [ -n "${CHECK_PRIVATE_TERMS:-}" ] && [ -f "$CHECK_PRIVATE_TERMS" ]; then
  while IFS= read -r term; do
    [ -n "$term" ] || continue
    if matches=$(grep -rEn --exclude-dir=.git -- "$term" . 2>/dev/null); then
      fail "private term matched:"$'\n'"$matches"
    fi
  done < "$CHECK_PRIVATE_TERMS"
fi

[ "$status" -eq 0 ] && echo "OK: all checks passed"
exit "$status"

#!/usr/bin/env bash
# Validate every docs/agents/*.md role definition. CI runs this on every
# push; scripts/validate-skills.sh is the skills counterpart.
#
# Checks per agent (README.md is the shelf guide and is exempt):
#   - closed frontmatter block opening the file
#   - name: present, kebab-case, <= 64 chars, matches filename
#   - description: present, 20..1024 chars
#   - non-empty body after the frontmatter
#   - no per-harness keys (model, tools, mode): they are not portable
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
agents_dir="$root/docs/agents"
failures=0
checked=0

fail() {
  printf 'FAIL %s: %s\n' "$1" "$2" >&2
  failures=$((failures + 1))
}

shopt -s nullglob
agent_files=("$agents_dir"/*.md)
shopt -u nullglob

if [ "${#agent_files[@]}" -eq 0 ]; then
  echo "no agents found under docs/agents/" >&2
  exit 1
fi

for agent_md in "${agent_files[@]}"; do
  name_file="$(basename "$agent_md" .md)"
  [ "$name_file" = "README" ] && continue
  checked=$((checked + 1))

  if ! head -n 1 "$agent_md" | grep -qx -- '---'; then
    fail "$name_file" "file must start with a --- frontmatter delimiter"
    continue
  fi

  closing="$(awk 'NR > 1 && /^---[[:space:]]*$/ {print NR; exit}' "$agent_md")"
  if [ -z "$closing" ]; then
    fail "$name_file" "frontmatter is not closed by a second --- line"
    continue
  fi

  frontmatter="$(awk -v end="$closing" 'NR > 1 && NR < end' "$agent_md")"
  body="$(awk -v start="$closing" 'NR > start' "$agent_md")"

  name="$(printf '%s\n' "$frontmatter" | sed -n 's/^name:[[:space:]]*//p' | head -n 1)"
  desc="$(printf '%s\n' "$frontmatter" | sed -n 's/^description:[[:space:]]*//p' | head -n 1)"

  [ -n "$name" ] || fail "$name_file" "frontmatter is missing name:"
  [ -n "$desc" ] || fail "$name_file" "frontmatter is missing description:"

  if printf '%s\n' "$frontmatter" | grep -Eq '^(model|tools|mode):'; then
    fail "$name_file" "per-harness keys (model/tools/mode) are not portable; routing lives in docs/models/routing.md"
  fi

  if [ -n "$name" ]; then
    if ! printf '%s' "$name" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$'; then
      fail "$name_file" "name '$name' must be kebab-case (lowercase letters, digits, hyphens)"
    fi
    [ "${#name}" -le 64 ] || fail "$name_file" "name exceeds 64 characters"
    [ "$name" = "$name_file" ] || fail "$name_file" "name '$name' must match its filename '$name_file'"
  fi

  if [ -n "$desc" ]; then
    [ "${#desc}" -le 1024 ] || fail "$name_file" "description exceeds 1024 characters"
    [ "${#desc}" -ge 20 ] || fail "$name_file" "description is too short to trigger reliably (state what + when)"
  fi

  [ -n "$(printf '%s' "$body" | tr -d '[:space:]')" ] || fail "$name_file" "empty body after frontmatter"
done

if [ "$failures" -gt 0 ]; then
  printf '%d failure(s) across %d agent(s)\n' "$failures" "$checked" >&2
  exit 1
fi

printf 'OK: %d agent(s) valid\n' "$checked"

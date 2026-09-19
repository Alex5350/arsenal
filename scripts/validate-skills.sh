#!/usr/bin/env bash
# Validate every docs/skills/*/SKILL.md against the Agent Skills conventions
# this hub follows (agentskills.io). CI runs this on every push.
#
# Checks per skill:
#   - SKILL.md exists and opens with a closed frontmatter block
#   - name: present, kebab-case, <= 64 chars, matches its directory name
#   - description: present, 20..1024 chars (long enough to trigger reliably)
#   - non-empty body after the frontmatter
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skills_dir="$root/docs/skills"
failures=0
checked=0

fail() {
  printf 'FAIL %s: %s\n' "$1" "$2" >&2
  failures=$((failures + 1))
}

shopt -s nullglob
skill_files=("$skills_dir"/*/SKILL.md)
shopt -u nullglob

if [ "${#skill_files[@]}" -eq 0 ]; then
  echo "no skills found under docs/skills/" >&2
  exit 1
fi

for skill_md in "${skill_files[@]}"; do
  skill_dir="$(dirname "$skill_md")"
  name_dir="$(basename "$skill_dir")"
  checked=$((checked + 1))

  if ! head -n 1 "$skill_md" | grep -qx -- '---'; then
    fail "$name_dir" "SKILL.md must start with a --- frontmatter delimiter"
    continue
  fi

  closing="$(awk 'NR > 1 && /^---[[:space:]]*$/ {print NR; exit}' "$skill_md")"
  if [ -z "$closing" ]; then
    fail "$name_dir" "frontmatter is not closed by a second --- line"
    continue
  fi

  frontmatter="$(awk -v end="$closing" 'NR > 1 && NR < end' "$skill_md")"
  body="$(awk -v start="$closing" 'NR > start' "$skill_md")"

  name="$(printf '%s\n' "$frontmatter" | sed -n 's/^name:[[:space:]]*//p' | head -n 1)"
  desc="$(printf '%s\n' "$frontmatter" | sed -n 's/^description:[[:space:]]*//p' | head -n 1)"

  [ -n "$name" ] || fail "$name_dir" "frontmatter is missing name:"
  [ -n "$desc" ] || fail "$name_dir" "frontmatter is missing description:"

  if [ -n "$name" ]; then
    if ! printf '%s' "$name" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$'; then
      fail "$name_dir" "name '$name' must be kebab-case (lowercase letters, digits, hyphens)"
    fi
    [ "${#name}" -le 64 ] || fail "$name_dir" "name exceeds 64 characters"
    [ "$name" = "$name_dir" ] || fail "$name_dir" "name '$name' must match its directory '$name_dir'"
  fi

  if [ -n "$desc" ]; then
    [ "${#desc}" -le 1024 ] || fail "$name_dir" "description exceeds 1024 characters"
    [ "${#desc}" -ge 20 ] || fail "$name_dir" "description is too short to trigger reliably (state what + when)"
  fi

  [ -n "$(printf '%s' "$body" | tr -d '[:space:]')" ] || fail "$name_dir" "empty body after frontmatter"
done

if [ "$failures" -gt 0 ]; then
  printf '%d failure(s) across %d skill(s)\n' "$failures" "$checked" >&2
  exit 1
fi

printf 'OK: %d skill(s) valid\n' "$checked"

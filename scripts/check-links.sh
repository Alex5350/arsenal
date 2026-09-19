#!/usr/bin/env bash
# Check that relative links and images in repository markdown resolve to real
# files. External http(s) links are out of scope: those are policy-reviewed,
# not CI-enforced, and CI should not fail because a third party had a bad day.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
broken=0
checked=0

report_broken() {
  printf 'BROKEN %s:%s -> %s\n' "$1" "$2" "$3" >&2
  broken=$((broken + 1))
}

shopt -s nullglob
md_files=("$root"/*.md "$root"/docs/*.md "$root"/docs/*/*.md "$root"/docs/*/*/*.md "$root"/.github/*.md)
shopt -u nullglob

for md in "${md_files[@]}"; do
  rel="${md#"$root"/}"
  dir="$(dirname "$md")"

  while IFS= read -r hit; do
    line_no="${hit%%:*}"
    match="${hit#*:}"
    target="${match#\]*(}"
    target="${target%)}"
    checked=$((checked + 1))

    case "$target" in
      http://*|https://*|mailto:*) continue ;;
      '#'*) continue ;;
    esac

    path_only="${target%%#*}"
    [ -n "$path_only" ] || continue

    if [ ! -e "$dir/$path_only" ]; then
      report_broken "$rel" "$line_no" "$target"
    fi
  done < <(grep -noE '\]\([^)]+\)' "$md" || true)
done

if [ "$broken" -gt 0 ]; then
  printf '%d broken link(s) of %d checked\n' "$broken" "$checked" >&2
  exit 1
fi

printf 'OK: %d link(s) resolve\n' "$checked"

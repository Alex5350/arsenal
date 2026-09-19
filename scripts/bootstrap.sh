#!/usr/bin/env bash
# One skills directory, many doors. docs/skills is the canonical library;
# each harness's project skills directory is a committed symlink to it
# (.claude/skills, .codex/skills, .opencode/skills, .github/skills).
# Those links ship with the repository, so a fresh clone serves every
# harness with no setup. This script verifies and repairs them, and can
# additionally wire user-level skill directories for other projects.
#
# Usage:
#   scripts/bootstrap.sh [--dry-run] [--force]   verify/repair project links
#   scripts/bootstrap.sh --user [--dry-run]      also link skills into
#                                                ~/.claude/skills, ~/.codex/skills,
#                                                ~/.copilot/skills (other projects)
#   scripts/bootstrap.sh --remove [--dry-run]    remove only links made by --user
#
# Windows note: git checkouts without symlink support materialize the links
# as text files containing the target path. Run this script from a POSIX
# shell (Git Bash) to repair them; see TECHNICAL.md.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skills_src="$root/docs/skills"
dry_run=0
force=0
user=0
remove=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=1 ;;
    --force) force=1 ;;
    --user) user=1 ;;
    --remove) remove=1 ;;
    -h|--help) sed -n '2,17p' "$0"; exit 0 ;;
    *) echo "unknown flag: $arg (see --help)" >&2; exit 2 ;;
  esac
done

run() {
  if [ "$dry_run" -eq 1 ]; then
    printf 'DRY  %s\n' "$*"
  else
    "$@"
  fi
}
say() { printf '     %s\n' "$*"; }

[ -d "$skills_src" ] || { echo "docs/skills not found at $skills_src" >&2; exit 1; }

# Project-level doors into docs/skills. Last verified: 2026-09.
# Claude Code: .claude/skills | Codex CLI: .codex/skills
# OpenCode: .opencode/skills | Copilot: .github/skills
project_links="
.claude/skills:../docs/skills
.codex/skills:../docs/skills
.opencode/skills:../docs/skills
.github/skills:../docs/skills
"

repair_project_links() {
  local repaired=0 ok=0 entry target expected
  while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    target="${entry%%:*}"
    expected="${entry#*:}"

    if [ -L "$root/$target" ]; then
      if [ "$(readlink "$root/$target")" = "$expected" ]; then
        say "$target -> $expected (ok)"
        ok=$((ok + 1))
        continue
      fi
      run rm "$root/$target"
      run ln -s "$expected" "$root/$target"
      say "$target: repointed to $expected"
      repaired=$((repaired + 1))
      continue
    fi

    if [ -f "$root/$target" ]; then
      # A regular file here is a Windows checkout placeholder (the link
      # target stored as text) or foreign content; either way, replace it.
      run rm "$root/$target"
      run ln -s "$expected" "$root/$target"
      say "$target: replaced file with symlink to $expected"
      repaired=$((repaired + 1))
      continue
    fi

    if [ -d "$root/$target" ]; then
      say "$target: real directory exists; not ours to replace."
      say "          remove or rename it to let arsenal own this path."
      continue
    fi

    run ln -s "$expected" "$root/$target"
    say "$target: created -> $expected"
    repaired=$((repaired + 1))
  done <<EOF
$project_links
EOF
  say "project links: $ok ok, $repaired repaired/created"
}

# ---------------------------------------------------------------- user ----
# User-level doors, for using arsenal skills in OTHER projects.
# ~/.claude/skills, ~/.codex/skills, ~/.copilot/skills (all per-harness
# documented personal skills locations; verified 2026-09).
user_dirs=(
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
  "$HOME/.copilot/skills"
)

wire_user_dirs() {
  local dir skill_dir skill
  for dir in "${user_dirs[@]}"; do
    if [ "$dry_run" -eq 0 ]; then
      mkdir -p "$dir"
    else
      say "would mkdir -p $dir"
    fi
    for skill_dir in "$skills_src"/*/; do
      [ -d "$skill_dir" ] || continue
      skill="$(basename "$skill_dir")"
      if [ -L "$dir/$skill" ] && [ "$(readlink "$dir/$skill")" = "$skill_dir" ]; then
        continue
      fi
      if [ -e "$dir/$skill" ] && [ "$force" -ne 1 ]; then
        say "$(basename "$(dirname "$dir")"): $skill exists and is not ours; skipping (use --force)"
        continue
      fi
      [ -e "$dir/$skill" ] && run rm -rf "$dir/$skill"
      run ln -s "$skill_dir" "$dir/$skill"
      say "$dir: linked $skill"
    done
  done
}

unwire_user_dirs() {
  local dir link
  for dir in "${user_dirs[@]}"; do
    [ -d "$dir" ] || continue
    for link in "$dir"/*; do
      [ -L "$link" ] || continue
      if [ "$(readlink "$link")" = "${skills_src%/}/$(basename "$link")/" ] \
        || [ "$(readlink "$link")" = "${skills_src%/}/$(basename "$link")" ]; then
        run rm "$link"
        say "removed $link"
      fi
    done
  done
}

repair_project_links

if [ "$remove" -eq 1 ]; then
  unwire_user_dirs
  echo "user-level links removed (project links are repo content and stay)"
  exit 0
fi

if [ "$user" -eq 1 ]; then
  wire_user_dirs
  echo
  echo "done: project links verified, user-level wiring complete."
else
  echo
  echo "done: project links verified. Use --user to also make the skills"
  echo "available in your other projects (claude, codex, copilot)."
fi

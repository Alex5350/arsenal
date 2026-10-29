#!/usr/bin/env bash
# User-level skills wiring, for using arsenal skills in OTHER projects.
#
# This project needs no setup: .agents/skills and .claude/agents are the
# canonical folders, read natively by every harness (Claude Code reaches
# .agents/skills through the committed plugin), and the Codex agent TOMLs
# are generated and committed (see scripts/sync.sh).
#
# Usage:
#   scripts/bootstrap.sh                         say that the project needs no setup
#   scripts/bootstrap.sh --user [--dry-run] [--force]
#                                                link skills into ~/.claude/skills
#                                                and ~/.agents/skills (other projects)
#   scripts/bootstrap.sh --remove [--dry-run]    remove links made by --user, including
#                                                ones from older layouts of this repo
#
# Windows note: run from Git Bash. The script sets
# MSYS=winsymlinks:nativestrict, so ln -s makes a real symlink (Developer
# Mode or admin rights required) or fails loudly; it never copies silently.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skills_src="$root/.agents/skills"
dry_run=0
force=0
user=0
remove=0

# Git Bash ln -s copies by default; nativestrict makes a real link or fails.
case "$(uname -s)" in
  MINGW*|MSYS*) export MSYS=winsymlinks:nativestrict ;;
esac

for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=1 ;;
    --force) force=1 ;;
    --user) user=1 ;;
    --remove) remove=1 ;;
    -h|--help) sed -n '2,19p' "$0"; exit 0 ;;
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

[ -d "$skills_src" ] || { echo ".agents/skills not found at $skills_src" >&2; exit 1; }

# ---------------------------------------------------------------- user ----
# User-level links, for using arsenal skills in OTHER projects.
# ~/.claude/skills: Claude Code. ~/.agents/skills: Codex, Copilot (CLI and
# VS Code), OpenCode, Cursor, Gemini CLI. Last verified: 2026-09.
user_dirs=(
  "$HOME/.claude/skills"
  "$HOME/.agents/skills"
)
# Older versions of this script linked into these as well. Codex still reads
# ~/.codex/skills, so linking there too would list every skill twice;
# --remove sweeps them instead.
legacy_dirs=(
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
      # -L as well as -e: a dangling link (e.g. to an old checkout path) still blocks ln -s.
      if { [ -e "$dir/$skill" ] || [ -L "$dir/$skill" ]; } && [ "$force" -ne 1 ]; then
        say "$(basename "$(dirname "$dir")"): $skill exists and is not ours; skipping (use --force)"
        continue
      fi
      { [ -e "$dir/$skill" ] || [ -L "$dir/$skill" ]; } && run rm -rf "$dir/$skill"
      run ln -s "$skill_dir" "$dir/$skill"
      [ "$dry_run" -eq 1 ] || say "$dir: linked $skill"
    done
  done
}

# Remove links that point into this repository, whichever layout made them
# (docs/skills, .claude/skills, or .agents/skills); every other link stays.
unwire_user_dirs() {
  local dir link
  for dir in "${user_dirs[@]}" "${legacy_dirs[@]}"; do
    [ -d "$dir" ] || continue
    for link in "$dir"/*; do
      [ -L "$link" ] || continue
      case "$(readlink "$link")" in
        "$root"/docs/skills/*|"$root"/.claude/skills/*|"$root"/.agents/skills/*)
          run rm "$link"
          say "removed $link"
          ;;
      esac
    done
  done
}

if [ "$remove" -eq 1 ]; then
  unwire_user_dirs
  echo "user-level links removed (project skills and agents are repo content and stay)"
  exit 0
fi

if [ "$user" -eq 1 ]; then
  wire_user_dirs
  echo
  echo "done: user-level skills wiring complete."
else
  echo "nothing to set up: this project's skills live in .agents/skills and its"
  echo "agents in .claude/agents; every harness reads them from a fresh clone"
  echo "(the Codex agent TOMLs are committed, see scripts/sync.sh)."
  echo "Use --user to also make the skills available in your other projects."
fi

#!/usr/bin/env bash
# Wire the shared skill library (docs/skills/*) into every harness installed
# on this machine, by symlink: one canonical copy, many harness views.
# Idempotent. Prints every action. Never modifies anything outside this
# repository (plus the user-level Codex skills directory).
#
# Usage:
#   scripts/bootstrap.sh             link skills into detected harnesses
#   scripts/bootstrap.sh --dry-run   show what would happen, change nothing
#   scripts/bootstrap.sh --force     replace foreign links/dirs at targets
#   scripts/bootstrap.sh --remove    remove only links that point at this repo
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skills_src="$root/docs/skills"
dry_run=0
force=0
remove=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=1 ;;
    --force) force=1 ;;
    --remove) remove=1 ;;
    -h|--help) sed -n '2,11p' "$0"; exit 0 ;;
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

# Harness mapping. Last verified: 2026-09; adjust the target paths here when
# a harness moves its skills directory, per docs/harness/README.md.
# Args: <harness label> <target skills dir>
wire_harness() {
  local harness="$1" target="$2" skill_dir skill dst
  if [ "$dry_run" -eq 0 ]; then
    mkdir -p "$target"
  else
    say "would mkdir -p $target"
  fi
  for skill_dir in "$skills_src"/*/; do
    [ -d "$skill_dir" ] || continue
    skill="$(basename "$skill_dir")"
    dst="$target/$skill"

    if [ -e "$dst" ] || [ -L "$dst" ]; then
      if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$skill_dir" ]; then
        say "$harness: $skill already linked (ok)"
        continue
      fi
      if [ "$force" -eq 1 ]; then
        run rm -rf "$dst"
      else
        say "$harness: $dst exists and is not ours; skipping (use --force)"
        continue
      fi
    fi

    run ln -s "$skill_dir" "$dst"
    say "$harness: linked $skill -> $dst"
  done
}

unwire_harness() {
  local target="$1" link
  [ -d "$target" ] || return 0
  for link in "$target"/*; do
    [ -L "$link" ] || continue
    if [ "$(readlink "$link")" = "${skills_src%/}/$(basename "$link")/" ] \
      || [ "$(readlink "$link")" = "${skills_src%/}/$(basename "$link")" ]; then
      run rm "$link"
      say "removed $link"
    fi
  done
}

detected=0
detect() {
  if command -v "$1" >/dev/null 2>&1; then
    detected=$((detected + 1))
    return 0
  fi
  return 1
}

# GitHub Copilot needs no symlink wiring: the coding agent reads AGENTS.md,
# which points at docs/skills paths directly (docs/harness/copilot.md).
if [ "$remove" -eq 1 ]; then
  detect claude && unwire_harness "$root/.claude/skills"
  detect opencode && unwire_harness "$root/.opencode/skills"
  detect codex && unwire_harness "$HOME/.codex/skills"
  echo "removal complete"
  exit 0
fi

detect claude && wire_harness "claude-code" "$root/.claude/skills"
detect opencode && wire_harness "opencode" "$root/.opencode/skills"
detect codex && wire_harness "codex" "$HOME/.codex/skills"

echo
if [ "$dry_run" -eq 1 ]; then
  echo "dry run complete; nothing changed"
elif [ "$detected" -eq 0 ]; then
  echo "no harness CLIs detected (looked for: claude, opencode, codex)"
  echo "GitHub Copilot needs no wiring: the coding agent reads AGENTS.md."
else
  echo "done. Restart open harness sessions to pick up the skills."
  if command -v copilot >/dev/null 2>&1; then
    say "Copilot CLI detected: install Superpowers per docs/superpowers/README.md"
  fi
fi

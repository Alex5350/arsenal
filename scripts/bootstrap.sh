#!/usr/bin/env bash
# One skills directory and one agents directory, many doors.
#
# docs/skills and docs/agents are the canonical libraries. Harnesses reach
# them through their own fixed paths:
#   skills doors  (committed dir symlinks): .claude/skills, .codex/skills,
#                 .opencode/skills, .github/skills -> ../docs/skills
#   agent doors   (committed per-file symlinks): .claude/agents/<name>.md,
#                 .opencode/agent/<name>.md, .github/chatmodes/<name>.chatmode.md
#                 -> ../../docs/agents/<name>.md
#   codex agents  (generated, gitignored): .codex/agents/<name>.toml, because
#                 Codex defines agents in TOML, not markdown
# The committed links ship with the repository, so a fresh clone serves every
# harness with no setup. This script verifies, repairs, and regenerates them.
#
# Usage:
#   scripts/bootstrap.sh [--dry-run] [--force]   verify/repair project doors
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
agents_src="$root/docs/agents"
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
    -h|--help) sed -n '2,23p' "$0"; exit 0 ;;
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

# --------------------------------------------------------- skills doors ----
# Last verified: 2026-09. Claude Code: .claude/skills | Codex CLI: .codex/skills
# OpenCode: .opencode/skills | Copilot (VS Code): .github/skills
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
  say "skills doors: $ok ok, $repaired repaired/created"
}

# --------------------------------------------------------- agents doors ----
# Per-file links: harness scanners read these directories verbatim and must
# see only agent files (a directory link would also expose README.md).
# Last verified: 2026-09. Claude Code: .claude/agents/<name>.md |
# OpenCode: .opencode/agent/<name>.md | VS Code Copilot: .github/chatmodes/
# <name>.chatmode.md
ensure_file_link() {
  local target="$1" expected="$2"
  if [ -L "$root/$target" ]; then
    if [ "$(readlink "$root/$target")" = "$expected" ]; then
      return 0
    fi
    run rm "$root/$target"
  elif [ -f "$root/$target" ]; then
    run rm "$root/$target"
  elif [ -d "$root/$target" ]; then
    say "$target: real directory/file exists; not ours to replace."
    return 0
  fi
  run ln -s "$expected" "$root/$target"
  say "$target: linked -> $expected"
}

toml_escape() {
  sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# Codex defines agents in TOML, so its door is generated from the canonical
# markdown and regenerated on every run. Do not edit the generated files.
generate_codex_agents() {
  local agent_md name desc body toml closing
  [ -d "$agents_src" ] || return 0
  for agent_md in "$agents_src"/*.md; do
    [ -f "$agent_md" ] || continue
    name="$(basename "$agent_md" .md)"
    [ "$name" = "README" ] && continue

    closing="$(awk 'NR > 1 && /^---[[:space:]]*$/ {print NR; exit}' "$agent_md")"
    desc=""
    body=""
    if [ -n "$closing" ]; then
      desc="$(awk -v end="$closing" 'NR > 1 && NR < end' "$agent_md" | sed -n 's/^description:[[:space:]]*//p' | head -n 1)"
      body="$(awk -v start="$closing" 'NR > start' "$agent_md")"
    fi
    [ -n "$desc" ] || desc="$name agent (see docs/agents/$name.md)"

    toml="$root/.codex/agents/$name.toml"
    if [ "$dry_run" -eq 1 ]; then
      say "would write $toml"
      continue
    fi
    mkdir -p "$root/.codex/agents"
    {
      printf '# Generated by scripts/bootstrap.sh from docs/agents/%s.md. Do not edit.\n' "$name"
      printf 'name = "%s"\n' "$name"
      printf 'description = "%s"\n' "$(printf '%s' "$desc" | toml_escape)"
      printf 'developer_instructions = """\n'
      printf '%s\n' "$body" | toml_escape
      printf '"""\n'
    } > "$toml"
    say ".codex/agents/$name.toml: generated"
  done
}

wire_agent_doors() {
  local agent_md name
  [ -d "$agents_src" ] || { say "docs/agents not found; skipping agent doors"; return 0; }
  for agent_md in "$agents_src"/*.md; do
    [ -f "$agent_md" ] || continue
    name="$(basename "$agent_md" .md)"
    [ "$name" = "README" ] && continue
    if [ "$dry_run" -eq 0 ]; then
      mkdir -p "$root/.claude/agents" "$root/.opencode/agent" "$root/.github/chatmodes"
    fi
    ensure_file_link ".claude/agents/$name.md" "../../docs/agents/$name.md"
    ensure_file_link ".opencode/agent/$name.md" "../../docs/agents/$name.md"
    ensure_file_link ".github/chatmodes/$name.chatmode.md" "../../docs/agents/$name.md"
  done
  generate_codex_agents
  say "agent doors: markdown links verified; codex tomls generated"
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
wire_agent_doors

if [ "$remove" -eq 1 ]; then
  unwire_user_dirs
  echo "user-level links removed (project doors are repo content and stay)"
  exit 0
fi

if [ "$user" -eq 1 ]; then
  wire_user_dirs
  echo
  echo "done: project doors verified, user-level skills wiring complete."
else
  echo
  echo "done: project doors verified. Use --user to also make the skills"
  echo "available in your other projects (claude, codex, copilot)."
fi

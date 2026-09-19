#!/usr/bin/env bash
# Adopt the arsenal template: give the Claude Code plugin bridge your project's
# name and drop in the starter files a consumer repository needs.
#
# Claude Code keys registered marketplaces by name per user, so two checkouts
# that both call theirs "arsenal" would share one registration and one would
# load the other's skills (docs/harness/claude-code.md). Run this once, right
# after "Use this template"; re-running is safe.
#
# Usage:
#   scripts/adopt.sh <project-name> [--dry-run]
#     <project-name>   lowercase letters, digits, hyphens: ^[a-z0-9][a-z0-9-]*$
#     --dry-run        print every change without writing anything
#
# What it does:
#   1. renames the plugin bridge to <project-name>: .claude-plugin/plugin.json
#      (name), .claude-plugin/marketplace.json (name, plugins[0].name),
#      .claude/settings.json (extraKnownMarketplaces key, enabledPlugins
#      <name>@<name>); JSON is rewritten with json, never sed
#   2. copies, only when the target is absent (never overwrites):
#        docs/templates/app-ci.yml            -> .github/workflows/app.yml
#        docs/templates/work-item.example.env -> .env
#      and replaces AGENTS.md with docs/templates/AGENTS.example.md while it
#      is still arsenal's own (a consumer-written AGENTS.md is left alone)
#   3. prints the manual steps that remain
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
name=""
dry_run=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=1 ;;
    -h|--help) sed -n '2,25p' "$0"; exit 0 ;;
    -*) echo "unknown flag: $arg (see --help)" >&2; exit 2 ;;
    *)
      [ -z "$name" ] || { echo "one project name expected, got '$name' and '$arg' (see --help)" >&2; exit 2; }
      name="$arg"
      ;;
  esac
done

[ -n "$name" ] || { echo "project name missing (see --help)" >&2; exit 2; }
if ! printf '%s' "$name" | grep -Eq '^[a-z0-9][a-z0-9-]*$'; then
  echo "invalid project name '$name': use lowercase letters, digits, hyphens (^[a-z0-9][a-z0-9-]*$)" >&2
  exit 2
fi

run() {
  if [ "$dry_run" -eq 1 ]; then
    printf 'DRY  %s\n' "$*"
  else
    "$@"
  fi
}
say() { printf '     %s\n' "$*"; }

# Windows has no python3 command; the hosted runner puts Python 3 on PATH as python.
python="$(command -v python3 || command -v python)" || { echo "python3 (or python) not found" >&2; exit 1; }

cd "$root"

# ------------------------------------------------------------- rename ----
# The current name comes from plugin.json, not a hardcoded "arsenal", so a
# second run (or a rename of a rename) finds nothing left to change.
"$python" - "$root" "$name" "$dry_run" <<'EOF'
import json
import os
import sys

root, name, dry_run = sys.argv[1], sys.argv[2], sys.argv[3] == "1"


def load(path):
    with open(os.path.join(root, path), encoding="utf-8") as f:
        return json.load(f)


def save(path, data):
    with open(os.path.join(root, path), "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")


plugin = load(".claude-plugin/plugin.json")
marketplace = load(".claude-plugin/marketplace.json")
settings = load(".claude/settings.json")
old = plugin.get("name")
if not old:
    sys.exit("error: .claude-plugin/plugin.json has no name; fix it by hand")

plugin["name"] = name
marketplace["name"] = name
marketplace["plugins"][0]["name"] = name

extra = settings.get("extraKnownMarketplaces", {})
if old in extra:
    settings["extraKnownMarketplaces"] = {name if k == old else k: v for k, v in extra.items()}
elif name not in extra:
    sys.exit(f"error: .claude/settings.json extraKnownMarketplaces has no key {old!r} to rename; fix it by hand")
enabled = settings.setdefault("enabledPlugins", {})
enabled.pop(f"{old}@{old}", None)
enabled[f"{name}@{name}"] = True

# Every file is computed before any is written, so a failure cannot leave them disagreeing.
changed = 0
for path, data in (
    (".claude-plugin/plugin.json", plugin),
    (".claude-plugin/marketplace.json", marketplace),
    (".claude/settings.json", settings),
):
    if data == load(path):
        continue
    changed += 1
    if dry_run:
        print(f"DRY  rename {old} -> {name} in {path}")
    else:
        save(path, data)
        print(f"     renamed {old} -> {name} in {path}")
if changed == 0:
    print(f"     plugin bridge already named {name}; nothing to rename")
EOF

# -------------------------------------------------------------- copies ----
copy_if_absent() {
  local src="$1" dst="$2"
  if [ -e "$dst" ]; then
    say "$dst exists; left as is (starter: $src)"
    return 0
  fi
  run mkdir -p "$(dirname "$dst")"
  run cp "$src" "$dst"
  [ "$dry_run" -eq 1 ] || say "copied $src -> $dst"
}

# AGENTS.md ships with the template, so "absent" never happens; replace it
# while it is still arsenal's own entry file (its first line names arsenal),
# and leave any consumer-written one alone.
replace_hub_agents_md() {
  local src="docs/templates/AGENTS.example.md" dst="AGENTS.md"
  if [ -e "$dst" ] && ! grep -q 'working in \*\*arsenal\*\*' "$dst"; then
    say "$dst is already yours; left as is (starter: $src)"
    return 0
  fi
  run cp "$src" "$dst"
  [ "$dry_run" -eq 1 ] || say "replaced arsenal's $dst with the starter $src; fill in the placeholders"
}

copy_if_absent docs/templates/app-ci.yml .github/workflows/app.yml
copy_if_absent docs/templates/work-item.example.env .env
replace_hub_agents_md

# ------------------------------------------------------------- by hand ----
echo
echo "done: $name adopted. Remaining steps, by hand:"
echo "  1. implement 'make test-unit' and 'make test-integration' for your stack in the"
echo "     Makefile (docs/standards/testing.md); .github/workflows/app.yml runs both on every PR"
echo "  2. edit .env: set GH_REPO=owner/repo, or remove that line to use the origin remote"
echo "     (docs/integrations/github.md); Jira and Azure DevOps settings are in the same file"
echo "  3. install Superpowers in each harness you use: docs/superpowers/README.md"
echo "  4. run 'make verify'"

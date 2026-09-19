#!/usr/bin/env bash
# Validate the hand-written manifests that wire the shared folders into each
# harness. CI runs this on every push. Only Python 3's standard library is
# used; an interpreter is present on macOS and on both CI runners (Windows
# runners name it python, not python3), so no toolchain gets installed.
# Last verified: 2026-09.
#
# Checks:
#   - .claude-plugin/plugin.json, .claude-plugin/marketplace.json,
#     .claude/settings.json, and opencode.json parse as JSON
#   - plugin.json skills: at least one path, and every path exists
#   - settings.json enabledPlugins enables every marketplace plugin as
#     <plugin>@<marketplace>
#   - the plugin bridge agrees on one name across files: plugin.json name ==
#     marketplace.json name == marketplace.json plugins[0].name == the single
#     settings.json extraKnownMarketplaces key, and enabledPlugins has
#     <name>@<name> true (scripts/adopt.sh renames all of them together)
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Windows has no python3 command; the hosted runner puts Python 3 on PATH as python.
python="$(command -v python3 || command -v python)" || { echo "python3 (or python) not found" >&2; exit 1; }

"$python" - "$root" <<'EOF'
import json
import os
import sys

root = sys.argv[1]
failures = []


def fail(path, reason):
    failures.append(f"FAIL {path}: {reason}")


def load(path):
    try:
        with open(os.path.join(root, path), encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        fail(path, "file is missing")
    except ValueError as e:
        fail(path, f"invalid JSON ({e})")
    return None


plugin = load(".claude-plugin/plugin.json")
marketplace = load(".claude-plugin/marketplace.json")
settings = load(".claude/settings.json")
load("opencode.json")

if plugin is not None:
    skills = plugin.get("skills", [])
    if isinstance(skills, str):
        skills = [skills]
    if not skills:
        fail(".claude-plugin/plugin.json", "skills lists no path; Claude Code would load no skills")
    for path in skills:
        if not os.path.isdir(os.path.join(root, path)):
            fail(".claude-plugin/plugin.json", f"skills path {path} does not exist")

if marketplace is not None and settings is not None:
    plugins = marketplace.get("plugins", [])
    enabled = settings.get("enabledPlugins", {})
    if not plugins:
        fail(".claude-plugin/marketplace.json", "plugins lists no plugin")
    for entry in plugins:
        key = f"{entry.get('name')}@{marketplace.get('name')}"
        if enabled.get(key) is not True:
            fail(".claude/settings.json", f"enabledPlugins does not enable {key}")

# Claude Code keys registered marketplaces by name per user, so the name must
# be the same in every file, or a checkout can load another project's skills.
if plugin is not None and marketplace is not None and settings is not None:
    name = plugin.get("name")
    if not name:
        fail(".claude-plugin/plugin.json", "name is missing")
    else:
        if marketplace.get("name") != name:
            fail(".claude-plugin/marketplace.json", f"name {marketplace.get('name')!r} != plugin.json name {name!r}")
        plugins = marketplace.get("plugins", [])
        if plugins and plugins[0].get("name") != name:
            fail(".claude-plugin/marketplace.json", f"plugins[0].name {plugins[0].get('name')!r} != plugin.json name {name!r}")
        keys = list(settings.get("extraKnownMarketplaces", {}))
        if keys != [name]:
            fail(".claude/settings.json", f"extraKnownMarketplaces keys {keys!r} != [{name!r}] (plugin.json name)")
        key = f"{name}@{name}"
        if settings.get("enabledPlugins", {}).get(key) is not True:
            fail(".claude/settings.json", f"enabledPlugins does not enable {key}")

for line in failures:
    print(line, file=sys.stderr)
if failures:
    print(f"{len(failures)} failure(s)", file=sys.stderr)
    sys.exit(1)
print("OK: manifests valid")
EOF

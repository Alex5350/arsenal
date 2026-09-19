# Claude Code

Last verified: 2026-09.

## What it reads first

`CLAUDE.md`, which exists here only to import the hub (`@docs/README.md` and
this guide). If `CLAUDE.md` were removed, Claude Code falls back to reading
`AGENTS.md`, which carries the same entry content; that fallback has been
native behavior since Claude Code 2.1.277.

## How skills reach it

Project skills: `.claude/skills/<skill>/SKILL.md`. `scripts/bootstrap.sh`
symlinks every `docs/skills/*` directory there. Personal (cross-project)
skills live in `~/.claude/skills/`. Skills are discovered by name and
description and loaded on demand (progressive disclosure), so the library
costs nothing until used.

## Model tiers

- `/model` sets the session model (executor default).
- Subagents declare their own model in their frontmatter: define a
  strategist plan-review subagent and a reviewer subagent per
  `docs/models/routing.md`.
- Agent Teams: lead agent strategist, workers executor, reviewer agent on
  diffs.
- Plugins: Superpowers installs via
  `/plugin marketplace add obra/superpowers-marketplace`; see
  [docs/superpowers/](../superpowers/README.md) for the pinned version.

## Gates

Claude Code runs `make test-unit` and `make test-integration` directly; the
[Agent tool](https://code.claude.com/docs) fan-out covers the research loop's
sub-agents. Hooks can enforce the test gate pre-commit if the team wants it
harder than convention.

## Quirks worth knowing

- `CLAUDE.md` supports `@path` imports; keep it a pointer file so the hub
  stays canonical.
- Skills, slash commands, and plugins overlap; in this repo, procedural
  knowledge is skills only, so one mechanism exists to maintain.
- `.claude/` is gitignored here because bootstrap generates it; commit
  `settings.json` deliberately (and negate it in `.gitignore`) only if the
  team adopts shared hooks.

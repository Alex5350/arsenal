# Claude Code

Last verified: 2026-09.

## What it reads first

`CLAUDE.md`, which exists here only to import the hub (`@docs/README.md` and
this guide). If `CLAUDE.md` were removed, Claude Code falls back to reading
`AGENTS.md`, which carries the same entry content; that fallback has been
native behavior since Claude Code 2.1.277.

## How skills reach it

Project skills: `.claude/skills/<skill>/SKILL.md`. Here `.claude/skills` is
a committed symlink to `docs/skills`, so the library is discoverable the
moment the repo is cloned. Personal (cross-project) skills live in
`~/.claude/skills/`, which `scripts/bootstrap.sh --user` can wire. Skills
are discovered by name and description and loaded on demand (progressive
disclosure), so the library costs nothing until used.

## Role agents

Claude Code discovers subagents in `.claude/agents/<name>.md` (project) or
`~/.claude/agents/` (personal). Here `.claude/agents` carries committed
per-file symlinks to [`docs/agents/`](../agents/README.md): researcher,
planner, and reviewer arrive with the clone, descriptions intact so
auto-delegation works. Assign each a model with `/model` at dispatch time
or a session-scoped `model:` override when you replace a link with a real
file for that purpose.

## Model tiers

- `/model` sets the session model (executor default).
- Subagents may declare `model:` in frontmatter (or `inherit`); the shared
  agent files omit it deliberately so one definition serves every harness.
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
- `.claude/` contents other than the committed skills symlink (settings,
  history) are gitignored; commit `settings.json` deliberately (and negate
  it in `.gitignore`) only if the team adopts shared hooks.

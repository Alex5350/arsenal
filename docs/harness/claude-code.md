# Claude Code

Last verified: 2026-09.

## What it reads first

`CLAUDE.md`, which exists here only to import the hub (`@docs/README.md` and
this guide). If `CLAUDE.md` were removed, Claude Code falls back to reading
`AGENTS.md`, which carries the same entry content; that fallback has been
native behavior since Claude Code 2.1.277.

## How skills reach it

Claude Code reads project skills from `.claude/skills/` and never from
`.agents/skills`, where the canonical library lives. The bridge is a
committed repo-local plugin, three small files:

- `.claude-plugin/plugin.json`: plugin `arsenal`, with
  `"skills": ["./.agents/skills"]`.
- `.claude-plugin/marketplace.json`: marketplace `arsenal` with that one
  plugin, `source: "./"`, `strict: true`.
- `.claude/settings.json`: `extraKnownMarketplaces.arsenal` (directory `./`)
  and `enabledPlugins["arsenal@arsenal"]: true`.

How it loads (Claude Code 2.1.278): the repo settings register the plugin
only after the teammate accepts the folder trust prompt, once per teammate
per repo. The first session in a trusted checkout (interactive or
`claude -p`) registers the marketplace in place (`installLocation` is the
repo path; nothing is copied to a cache) but does not load its skills yet.
From the second session on, every session, headless `claude -p` included,
loads the five skills (debug log:
`Loaded 5 skills from plugin arsenal custom path: <repo>/.agents/skills`).
The one case that needs `claude -p --plugin-dir .` is a checkout where no
earlier session has run: a fresh machine, a CI runner, or a second clone or
worktree of the same repo on one machine (marketplace names are per user).
Skills are named
`/arsenal:<skill>` (for example `/arsenal:test-gate`); the model lists them
as `arsenal:<name>`. `claude plugin validate --strict .` checks the bridge
locally; CI runs `scripts/validate-manifests.sh` for the same facts.

When adopting the template, rename `arsenal` in the three files:
`plugin.json` `name`, `marketplace.json` `name` and its plugin's `name`, and
the two `settings.json` keys; `scripts/adopt.sh <name>` does exactly this,
and `scripts/validate-manifests.sh` fails when the four disagree. This is
required, not cosmetic: Claude Code
keys registered marketplaces by name per user, so two projects on one
machine that both call theirs `arsenal` would share one registration and
one of them would load the other's skills.

Personal (cross-project) skills live in `~/.claude/skills/`, which
`scripts/bootstrap.sh --user` can wire. Skills are discovered by name and
description and loaded on demand (progressive disclosure), so the library
costs nothing until used.

## Role agents

Claude Code discovers subagents in `.claude/agents/<name>.md` (project) or
`~/.claude/agents/` (personal). Here `.claude/agents` is the canonical
agent library itself (contract: [`docs/agents/`](../agents/README.md)):
researcher, planner, and reviewer arrive with the clone, descriptions
intact so auto-delegation works. Assign each a model with `/model` at
dispatch time; the committed files carry no `model:` key by design.

## Model tiers

- `/model` sets the session model (executor default).
- Subagents may declare `model:` in frontmatter (or `inherit`); the shared
  agent files omit it deliberately so one definition serves every harness.
- Agent Teams: lead agent strategist, workers executor, reviewer agent on
  diffs.
- Plugins: Superpowers installs via
  `/plugin install superpowers@claude-plugins-official` (or from
  `obra/superpowers-marketplace`); see
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
- `.claude/` contents other than the committed `agents/` folder and
  `settings.json` (history, local state) are gitignored. `settings.json` is
  committed, and negated in `.gitignore`, because it carries the plugin
  registration; add shared hooks there deliberately, if at all.

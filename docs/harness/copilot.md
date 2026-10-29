# GitHub Copilot

Last verified: 2026-09.

## What it reads first

Two surfaces, one hub:

- **VS Code chats and agent sessions**: `.github/copilot-instructions.md`,
  which restates the essentials and defers to `AGENTS.md` and `docs/`.
- **Copilot coding agent** (assigned issues and PRs on github.com): reads
  `AGENTS.md` natively, so the universal entry already governs it.

## How skills reach it

Copilot (CLI, VS Code, and the coding agent) reads project skills from
`.agents/skills/` natively, and personal skills from `~/.agents/skills/`.
In this repository `.agents/skills` is the canonical library, so VS Code
and CLI sessions see it locally and the Copilot coding agent sees the same
skills when it checks the repository out on github.com; nothing extra to
install. `copilot skill list` shows the five under "Project skills", and
`copilot instruction list` shows `copilot-instructions.md`, `AGENTS.md`, and
`CLAUDE.md` (Copilot CLI 1.0.86). `scripts/bootstrap.sh --user` links the
skills into `~/.agents/skills` for your other projects.

## Role agents

Copilot CLI and VS Code read custom agents from `.claude/agents/*.md`
natively (per GitHub's docs; no CLI listing exists to confirm it), so the
canonical files (contract: [`docs/agents/`](../agents/README.md)) arrive
with the clone: `researcher.md`, `planner.md`, `reviewer.md`, frontmatter
descriptions intact so the agent picker explains each role. Pick a role in
the agent selector; the model picker casts the tier per
`docs/models/routing.md`. Whether the Copilot coding agent reads
`.claude/agents` is undocumented as of 2026-09. VS Code chat modes
(`.github/chatmodes/*.chatmode.md`) are legacy, replaced by custom agents,
so this repository ships none.

## Model tiers

- The model is chosen per session in the chat model picker; org policy can
  pin defaults. Keep strategist models for planning and review
  conversations, executor models for agent-mode implementation, per
  `docs/models/routing.md`.
- The coding agent's model is set at the organization level; point it at
  the executor tier and keep strategist work in interactive sessions.

## Gates

VS Code agent mode runs the make targets in its terminal. The Copilot
coding agent gets CI through the standard GitHub workflows; it sees check
results on its own PRs, which is where `docs/templates/app-ci.yml` carries
the gate.

## Quirks worth knowing

- Copilot CLI exists too and installs Superpowers via its plugin
  marketplace; see [docs/superpowers/](../superpowers/README.md).
- Custom instructions files are prompt-prepended: keep them short and
  pointed, which is exactly why the adapter defers to `docs/` instead of
  duplicating it.
- MCP servers for VS Code are declared in `.vscode/mcp.json` (workspace) or
  user settings; Jira and Azure DevOps MCP servers are an alternative to
  the CLI backends in `docs/integrations/`.

# GitHub Copilot

Last verified: 2026-09.

## What it reads first

Two surfaces, one hub:

- **VS Code chats and agent sessions**: `.github/copilot-instructions.md`,
  which restates the essentials and defers to `AGENTS.md` and `docs/`.
- **Copilot coding agent** (assigned issues and PRs on github.com): reads
  `AGENTS.md` natively, so the universal entry already governs it.

## How skills reach it

Copilot supports the Agent Skills standard for workspace skills; VS Code
discovers skills directories in the workspace, and the Copilot coding agent
reads repository skills on github.com. `scripts/bootstrap.sh` links the
library into the workspace skills location. Because the coding agent runs on
github.com, repository-committed skill folders travel with the repo; teams
that want that behavior can commit the links' targets and drop them from
`.gitignore` (the guide for that choice is
[ADR-002](../ARCHITECTURE.md)).

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

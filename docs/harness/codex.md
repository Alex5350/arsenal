# Codex CLI

Last verified: 2026-09.

## What it reads first

`AGENTS.md` at the repository root (native behavior; nested AGENTS.md files
merge root-down). No adapter file is needed; the universal entry is already
in the format Codex expects.

## How skills reach it

Codex supports the Agent Skills standard: `~/.codex/skills/<skill>/SKILL.md`
(user scope). `scripts/bootstrap.sh` links the library there when Codex is
installed. Verify the current path with Codex's own skills documentation if
a release moves it; the bootstrap prints every link it creates.

## Model tiers

- Default model: `model` in `~/.codex/config.toml` (executor default).
- Strategist sessions: `codex -m <strategist-model>` for planning and review
  passes, per `docs/models/routing.md`.
- Approval modes: keep workspace-write sandbox for execution; escalate to
  broader permissions only for the publishing phase, where a human co-signs
  anyway.
- Superpowers installs as a Codex plugin (`/plugins`, search "superpowers");
  see [docs/superpowers/](../superpowers/README.md).

## Gates

Codex runs the make targets directly. Its sandbox is an asset for the test
gate: a suite that only passes with network access it should not need is a
finding, not a pass.

## Quirks worth knowing

- Codex honors nested `AGENTS.md` files; consumer repos can add per-package
  AGENTS.md that narrow, not contradict, the root entry.
- Config is TOML at `~/.codex/config.toml`; MCP servers are configured there
  too (`mcp_servers`), which is where a Jira or Azure DevOps MCP server
  would go if the team prefers MCP over CLI for tracking.

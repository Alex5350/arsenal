# Harness guides

How each harness consumes this hub. Every guide answers the same five
questions: what it reads first, how skills reach it, how model tiers are
wired, how it runs the gates, and its quirks.

| Harness | Reads first | Skills arrive via | Guide |
| --- | --- | --- | --- |
| Claude Code | `CLAUDE.md` (@imports), `AGENTS.md` fallback | `.agents/skills` through the committed plugin (`.claude-plugin/`) | [claude-code.md](claude-code.md) |
| Codex CLI | `AGENTS.md` | `.agents/skills` (native) | [codex.md](codex.md) |
| OpenCode | `AGENTS.md` + `opencode.json` | `.agents/skills` (native) | [opencode.md](opencode.md) |
| GitHub Copilot | `.github/copilot-instructions.md`; coding agent reads `AGENTS.md` | `.agents/skills` (native) | [copilot.md](copilot.md) |

The [skills library](../skills/README.md) lives in `.agents/skills`, the
cross-tool folder, once. Codex, Copilot, and OpenCode read it natively.
Claude Code is the one harness that does not, so a committed repo-local
plugin (`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`,
`.claude/settings.json`) points it at the same folder. No symlinks, no
copies, zero setup after clone, on any OS.

## Role agents

The [role agents](../agents/README.md) (researcher, planner, reviewer) are
defined once in `.claude/agents/`:

| Harness | Agents directory | Mechanism |
| --- | --- | --- |
| Claude Code | `.claude/agents/<name>.md` | canonical, native |
| Copilot (CLI, VS Code) | `.claude/agents/<name>.md` | canonical, native |
| OpenCode | `.claude/agents/<name>.md` | `opencode.json` subagent with a `{file:}` prompt pointer |
| Codex CLI | `.codex/agents/<name>.toml` | generated TOML (committed, `scripts/sync.sh`) |

Facts in these guides that depend on vendor behavior carry a
`Last verified: YYYY-MM` line. When a harness updates, fix the guide, not
the hub.

## Adding the next harness

Any tool that reads `AGENTS.md` or the [Agent Skills](https://agentskills.io)
standard works with the same three steps:

1. **Entry**: prefer `AGENTS.md` (already at the root). If the tool wants
   its own file, add a root adapter that points at `docs/README.md` and
   carries no guidance of its own.
2. **Skills and agents**: if the tool reads `.agents/skills` (and
   `.claude/agents` for agents) natively, nothing is needed; confirm the
   tool lists them. Otherwise bridge with a committed config file that
   points at the canonical folder (the way `.claude-plugin/` does for Claude
   Code and `opencode.json` does for OpenCode agents), and confirm the tool
   lists them. Generate a file only when the tool's format forces it (Codex
   agents are TOML); then it goes in `scripts/sync.sh` and CI checks it.
   Never add a symlink or a copy.
3. **Guide**: add `docs/harness/<tool>.md` answering the same five
   questions, update the matrix above, and link it from the root README.

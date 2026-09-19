# Harness guides

How each harness consumes this hub. Every guide answers the same five
questions: what it reads first, how skills reach it, how model tiers are
wired, how it runs the gates, and its quirks.

| Harness | Reads first | Skills arrive via | Guide |
| --- | --- | --- | --- |
| Claude Code | `CLAUDE.md` (@imports), `AGENTS.md` fallback | `.claude/skills/` (bootstrap) | [claude-code.md](claude-code.md) |
| Codex CLI | `AGENTS.md` | user skills dir (bootstrap) | [codex.md](codex.md) |
| OpenCode | `AGENTS.md` + `opencode.json` | `.opencode/skills/` (bootstrap) | [opencode.md](opencode.md) |
| GitHub Copilot | `.github/copilot-instructions.md`; coding agent reads `AGENTS.md` | workspace skills (bootstrap) | [copilot.md](copilot.md) |

Facts in these guides that depend on vendor behavior carry a
`Last verified: YYYY-MM` line. When a harness updates, fix the guide, not
the hub.

## Adding the next harness

Any tool that reads `AGENTS.md` or the [Agent Skills](https://agentskills.io)
standard works with the same three steps:

1. **Entry**: prefer `AGENTS.md` (already at the root). If the tool wants
   its own file, add a root adapter that points at `docs/README.md` and
   carries no guidance of its own.
2. **Skills**: add the tool's skill directory to the mapping table at the
   top of `scripts/bootstrap.sh`, rerun it, confirm the tool lists the
   skills.
3. **Guide**: add `docs/harness/<tool>.md` answering the same five
   questions, update the matrix above, and link it from the root README.

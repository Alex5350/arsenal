# Harness guides

How each harness consumes this hub. Every guide answers the same five
questions: what it reads first, how skills reach it, how model tiers are
wired, how it runs the gates, and its quirks.

| Harness | Reads first | Skills arrive via | Guide |
| --- | --- | --- | --- |
| Claude Code | `CLAUDE.md` (@imports), `AGENTS.md` fallback | `.claude/skills` symlink (committed) | [claude-code.md](claude-code.md) |
| Codex CLI | `AGENTS.md` | `.codex/skills` symlink (committed) | [codex.md](codex.md) |
| OpenCode | `AGENTS.md` + `opencode.json` | `.opencode/skills` symlink (committed) | [opencode.md](opencode.md) |
| GitHub Copilot | `.github/copilot-instructions.md`; coding agent reads `AGENTS.md` | `.github/skills` symlink (committed) | [copilot.md](copilot.md) |

All four skills directories are committed relative symlinks to
[`docs/skills`](../skills/README.md): one canonical library, every harness's
native discovery pointed at it, zero setup after clone.

Facts in these guides that depend on vendor behavior carry a
`Last verified: YYYY-MM` line. When a harness updates, fix the guide, not
the hub.

## Adding the next harness

Any tool that reads `AGENTS.md` or the [Agent Skills](https://agentskills.io)
standard works with the same three steps:

1. **Entry**: prefer `AGENTS.md` (already at the root). If the tool wants
   its own file, add a root adapter that points at `docs/README.md` and
   carries no guidance of its own.
2. **Skills**: add the tool's project skill directory to the mapping table
   at the top of `scripts/bootstrap.sh`, commit a relative symlink from that
   directory to `docs/skills`, run the script, and confirm the tool lists
   the skills.
3. **Guide**: add `docs/harness/<tool>.md` answering the same five
   questions, update the matrix above, and link it from the root README.

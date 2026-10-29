# Architecture

![Hub diagram](assets/hub-diagram.svg)

## The shape: hub and adapters

One canonical knowledge base (`docs/`), many thin adapters at the repository
root, one skills folder and one agents folder that every harness reads where
they live: natively, through a committed pointer (the Claude Code plugin,
the OpenCode agent entries), or, for Codex agents only, as generated TOML.

```
Claude Code ──── CLAUDE.md ────────────────┐
Codex CLI ────── AGENTS.md ────────────────┤
OpenCode ─────── AGENTS.md + opencode.json ├──► docs/  (the hub)
GitHub Copilot ─ .github/copilot-          │
                 copilot-instructions.md ───┘
```

The hub is divided into shelves (`harness/`, `standards/`, `workflows/`,
`models/`, `skills/`, `integrations/`, `superpowers/`, `templates/`), each with
a README that states its own contract.

## Why this shape: decisions

**ADR-001: `docs/` is canonical; adapters only point.** Every harness reads a
different entry file, but no guidance lives in those files. Duplicated guidance
drifts within weeks; a pointer cannot drift. The AGENTS.md open standard covers
Codex CLI, OpenCode, and the Copilot coding agent natively, and Claude Code
reads `AGENTS.md` as a fallback, so one file reaches everyone; `CLAUDE.md`
exists to use Claude Code's native `@path` imports for the same content.

**ADR-002: canonical skills in the cross-tool `.agents/skills/`, role agents
in `.claude/agents/`, Claude Code bridged by a committed plugin.** Revised
2026-09-19; supersedes the 2026-09-18 revision (canonical `.claude/skills`
plus a generated `.agents/skills` mirror for Codex) and the original ADR-002
(canonical `docs/skills` reached through committed symlinks). Symlinks were
rejected because Git for Windows checks them out as plain text files by
default (`core.symlinks` is `false`; real links need Developer Mode or admin
rights), so that design failed exactly where a template must just work.
Copies were rejected because a second skills folder means a sync step after
every edit, a drift check in CI, and duplicate names in the harnesses that
scan both folders. Every skill now lives once in `.agents/skills/`, the
folder Codex, Copilot (CLI, VS Code, coding agent), and OpenCode read
natively, and every role agent lives once in `.claude/agents/`, read
natively by Claude Code and Copilot. This is the one deliberate exception to
ADR-001: Claude Code and Codex share no skills folder, and neither accepts a
configured one, so without symlinks no folder under `docs/` can reach both
([evidence and the 2026-09-19 test log](research/shared-ai-resources-without-symlinks.md)).
Claude Code does not read `.agents/skills`, so a committed repo-local plugin
serves it the same folder: `.claude-plugin/plugin.json`,
`.claude-plugin/marketplace.json`, and `.claude/settings.json`, hand-written
and checked by `scripts/validate-manifests.sh`. The bridge has two costs:
skills carry the `arsenal:` prefix in Claude Code, and a checkout where no
Claude Code session has run yet (a fresh machine, a CI runner, or a second
clone or worktree of the same repo on one machine) must pass
`claude -p --plugin-dir .`, because the repo settings register the plugin
only after the trust prompt and the first session. The only generated files
are `.codex/agents/*.toml`, built by `scripts/sync.sh` because Codex agents
are TOML-only; OpenCode reaches the agents through hand-written
`opencode.json` entries whose `prompt` is `{file:./.claude/agents/<name>.md}`.
CI runs `scripts/sync.sh --check`. One place to edit per kind, no sync step
for skills, and a fresh clone serves every harness on any OS; the Copilot
coding agent receives the same skills when it checks the repository out on
github.com. `scripts/bootstrap.sh --user` still wires user-level skill
directories for your other projects.

**ADR-003: Superpowers is referenced and pinned, not vendored.** Superpowers is
a 289k-star, MIT-licensed skill framework with native plugin distribution for
more than a dozen harnesses. Vendoring would freeze a fast-moving upstream and
create update chores. Arsenal records the pinned version and per-harness
install commands in `docs/superpowers/`, and documents the gaps arsenal fills
itself (tiered routing, work tracking, publishing).

**ADR-004: validation is shell, not a toolchain.** A template for any stack
must run anywhere, so CI checks are bash scripts plus shellcheck and gitleaks.
There is no Node, Python, or .NET dependency to install before the hub can
prove itself: nothing gets installed, and `scripts/validate-manifests.sh`
uses the Python 3 that every runner already has.

**ADR-005: tracking behind one script contract.** The loop is tracker-agnostic
because all phase docs and skills call `scripts/work-item.sh` with the same
subcommands (`create`, `comment`, `transition`, `link`) instead of calling
`gh`, `jira`, or `az boards` directly. Swapping backends is a config change,
not a docs rewrite.

**ADR-006: one agent library, minimal frontmatter.** Role
agents (researcher, planner, reviewer) are markdown files in `.claude/agents/`
(see ADR-002) with exactly two frontmatter keys, `name` and `description`,
because those are the only keys every consumer reads: Claude Code and
Copilot (CLI and VS Code) load `.claude/agents/<name>.md` directly, and
OpenCode loads the same file through an `opencode.json` subagent whose
`prompt` is `{file:./.claude/agents/<name>.md}`. Codex defines agents in
TOML, so `scripts/sync.sh` builds `.codex/agents/<name>.toml` from the
canonical markdown. Per-harness keys
(`model`, `tools`, `mode`) are deliberately absent: their value formats
differ per harness, so a shared file cannot carry them; model assignment
lives in `models/routing.md` and applies at the session level.

## How work flows through the loop

![Loop diagram](assets/loop-diagram.svg)

1. **Research** (strategist): questions answered with citations, written to
   `docs/research/` in the consumer repo. Skill: `research-loop`.
2. **Planning** (strategist): a written plan with tasks, acceptance criteria,
   and model assignments. Skill: `planner-executor-handoff`. Gate: human or
   strategist approves the plan.
3. **Execution** (executor): implementation in a worktree, one work item at a
   time. Superpowers skills (TDD, worktrees, plan execution) carry the
   methodology.
4. **Verification** (reviewer): unit and integration suites green, diff
   reviewed against the plan. Skill: `test-gate`. Gate: no red, no skip.
5. **Tracking** (executor): every task mirrored and transitioned in GitHub,
   Jira, or Azure DevOps. Skill: `work-tracking`; script: `work-item.sh`.
6. **Publishing** (strategist + human): release notes, tag, artifact
   publication. Skill: `release-publish`.

The loop then repeats; research findings from one cycle seed the next.

## Drift management

External facts move. Each file that states one carries a `Last verified:`
date. The current ledger:

| Fact | Where | Last verified |
| --- | --- | --- |
| Claude Code reads `AGENTS.md` as fallback; `CLAUDE.md` supports `@path` imports; never reads `.agents/` directly, so the committed repo-local plugin bridges it: loads after the trust prompt from the second session on, `--plugin-dir .` where no session has run | `harness/claude-code.md` | 2026-09 |
| Codex CLI reads `AGENTS.md`; skills only from `.agents/skills/`; agents from `.codex/agents/*.toml` in trusted projects | `harness/codex.md` | 2026-09 |
| OpenCode reads skills from `.agents/skills/`; role agents through `opencode.json` `{file:}` prompts; `model` is `provider/model`, `permission` replaces `tools` | `harness/opencode.md` | 2026-09 |
| Copilot reads `.github/copilot-instructions.md`; coding agent reads `AGENTS.md`; skills from `.agents/skills/`, agents from `.claude/agents/` | `harness/copilot.md` | 2026-09 |
| Agent Skills standard: `name`, `description` frontmatter, progressive disclosure | `skills/README.md` | 2026-09 |
| Claude Code and Copilot (CLI, VS Code) agents at `.claude/agents/*.md`; OpenCode through `opencode.json` pointers to the same files; Codex agents at `.codex/agents/*.toml` (TOML) | `agents/README.md` | 2026-09 |
| Claude Code and Codex share no skills folder; Git for Windows checks symlinks out as text by default | `research/shared-ai-resources-without-symlinks.md` | 2026-09 |
| Frontier model names per provider | `models/routing.md` | 2026-09 |
| Superpowers install commands per harness | `superpowers/README.md` | 2026-09 |

## Limits, honestly stated

- Harness skill-directory paths are the least stable fact in the system;
  each harness guide states where its tool looks, the Claude Code bridge is
  three small JSON files that `scripts/validate-manifests.sh` checks, and CI
  fails when the generated Codex TOML or an `opencode.json` description
  drifts from `.claude/agents/`.
- The hub governs agent behavior through instructions and CI; it cannot
  enforce anything inside a harness session beyond what the harness itself
  enforces (permissions, hooks).
- The routing matrix names example models as a dated snapshot. Pin your own
  in the consumer repo and re-verify quarterly.

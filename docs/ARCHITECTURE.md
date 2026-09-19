# Architecture

![Hub diagram](assets/hub-diagram.svg)

## The shape: hub and adapters

One canonical knowledge base (`docs/`), many thin adapters at the repository
root, one installer that fans shared skills out to each harness's expected
location on a developer's machine.

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

**ADR-002: skills fan out by symlink, not by copy.** The canonical copy of every
skill lives in `docs/skills/`. `scripts/bootstrap.sh` links each skill into the
skill directories the installed harnesses expect (`.claude/skills/` for Claude
Code, `.opencode/skills/` for OpenCode, and so on). One copy means one place to
fix; symlinks mean no stale per-harness duplicates. The link targets are
machine-local state and are gitignored.

**ADR-003: Superpowers is referenced and pinned, not vendored.** Superpowers is
a 289k-star, MIT-licensed skill framework with native plugin distribution for
more than a dozen harnesses. Vendoring would freeze a fast-moving upstream and
create update chores. Arsenal records the pinned version and per-harness
install commands in `docs/superpowers/`, and documents the gaps arsenal fills
itself (tiered routing, work tracking, publishing).

**ADR-004: validation is shell, not a toolchain.** A template for any stack
must run anywhere, so CI checks are bash scripts plus shellcheck and gitleaks.
There is no Node, Python, or .NET dependency to install before the hub can
prove itself.

**ADR-005: tracking behind one script contract.** The loop is tracker-agnostic
because all phase docs and skills call `scripts/work-item.sh` with the same
subcommands (`create`, `comment`, `transition`, `link`) instead of calling
`gh`, `jira`, or `az boards` directly. Swapping backends is a config change,
not a docs rewrite.

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
| Claude Code reads `AGENTS.md` as fallback; `CLAUDE.md` supports `@path` imports | `harness/claude-code.md` | 2026-09 |
| Codex CLI reads `AGENTS.md`; skills supported | `harness/codex.md` | 2026-09 |
| OpenCode skills at `.opencode/skills/`, agents and models in `opencode.json` | `harness/opencode.md` | 2026-09 |
| Copilot reads `.github/copilot-instructions.md`; coding agent reads `AGENTS.md` | `harness/copilot.md` | 2026-09 |
| Agent Skills standard: `name`, `description` frontmatter, progressive disclosure | `skills/README.md` | 2026-09 |
| Frontier model names per provider | `models/routing.md` | 2026-09 |
| Superpowers install commands per harness | `superpowers/README.md` | 2026-09 |

## Limits, honestly stated

- Harness skill-directory paths are the least stable fact in the system; the
  bootstrap script prints what it did and links nothing silently.
- The hub governs agent behavior through instructions and CI; it cannot
  enforce anything inside a harness session beyond what the harness itself
  enforces (permissions, hooks).
- The routing matrix names example models as a dated snapshot. Pin your own
  in the consumer repo and re-verify quarterly.

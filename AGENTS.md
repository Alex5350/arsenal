# AGENTS.md

You are a coding agent working in **arsenal**, a provider-agnostic AI development hub.
This file is the universal entry point: Claude Code, Codex CLI, OpenCode, and GitHub
Copilot all read it. The full knowledge base lives in [`docs/`](docs/README.md).

## What this repository is

arsenal is a template repository teams clone so that every AI coding harness shares
one source of truth: skills, engineering standards, model routing policy, and work
tracking. It is stack-agnostic and carries no application code of its own. Consumer
repositories keep their own tech stack; arsenal governs how agents work in it.

## Operating principles

1. **One hub, many harnesses.** `docs/` is canonical. Never duplicate guidance into a
   harness-specific file; root adapter files only point into `docs/`.
2. **Follow the loop.** Research, plan, execute, verify, track, publish. Phase
   definitions and gates live in `docs/workflows/`.
3. **Route by tier.** Strategist models plan and review; executor models write code.
   The current matrix and per-harness wiring live in `docs/models/routing.md`.
4. **No handoff without green.** Work moves to the next phase only after the test
   gate defined in `docs/standards/testing.md` passes.
5. **Track all work.** Every unit of work is mirrored to the team tracker (GitHub
   Issues, Jira, or Azure DevOps) using `docs/integrations/` and
   `scripts/work-item.sh`.
6. **Skills are the unit of reuse.** Procedural knowledge goes in `docs/skills/` as
   Agent Skills (SKILL.md, the open standard at agentskills.io). Each harness's
   project skills directory (`.claude/skills`, `.codex/skills`,
   `.opencode/skills`, `.github/skills`) is a committed symlink to
   `docs/skills`; edit skills only in `docs/skills/`. Authoring rules:
   `docs/skills/README.md`.

## Where things live

| You need | Read |
| --- | --- |
| The full hub map and reading order | [docs/README.md](docs/README.md) |
| How your harness consumes this repo | [docs/harness/](docs/harness/README.md) |
| Engineering standards | [docs/standards/](docs/standards/README.md) |
| The six-phase delivery loop | [docs/workflows/](docs/workflows/README.md) |
| Model tiers and routing | [docs/models/routing.md](docs/models/routing.md) |
| Shared skills library | [docs/skills/](docs/skills/README.md) |
| Work tracking backends | [docs/integrations/](docs/integrations/README.md) |
| Superpowers methodology layer | [docs/superpowers/](docs/superpowers/README.md) |

## Hard rules

- Never commit secrets or credentials. See `docs/standards/security.md`.
- Never disable or skip a test to make progress. Fix the code or fix the test.
- Conventional commits only. See `docs/standards/git.md`.
- Stamp work-item IDs in branch names, commits, and pull requests.
- When a harness default or a stale habit conflicts with this repository,
  this repository wins.

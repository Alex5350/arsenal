# The hub

Everything an AI coding agent or a teammate needs to know about how work happens
here lives under `docs/`. Root-level adapter files point here; nothing of
substance lives anywhere else.

## Reading order

**For humans, first visit:**

1. [`ARCHITECTURE.md`](ARCHITECTURE.md) - how the hub is wired and why
2. [`standards/`](standards/README.md) - the rules of the road
3. [`workflows/`](workflows/README.md) - the six-phase delivery loop
4. [`models/routing.md`](models/routing.md) - which model does which work

**For agents:** [`AGENTS.md`](../AGENTS.md) at the repository root is the entry
point. It sends you to the right shelf below.

## The shelves

| Shelf | What it holds |
| --- | --- |
| [`harness/`](harness/README.md) | How each harness (Claude Code, Codex CLI, OpenCode, Copilot) consumes this hub, and how to add the next one |
| [`standards/`](standards/README.md) | Git, testing, security, code review, documentation: the non-negotiables |
| [`workflows/`](workflows/README.md) | The six-phase loop: research, planning, execution, verification, tracking, publishing |
| [`models/`](models/routing.md) | Tiered model routing: strategist, executor, reviewer, and the per-harness wiring |
| [`skills/`](skills/README.md) | The shared Agent Skills library, authored to the open SKILL.md standard |
| [`integrations/`](integrations/README.md) | Work tracking backends: GitHub Issues, Jira, Azure DevOps |
| [`superpowers/`](superpowers/README.md) | The pinned Superpowers methodology layer: what it provides, what arsenal adds on top |
| [`templates/`](templates/) | Copy-and-adapt starters: application CI workflow, tracking config |

## Contributing to the hub

- Change the hub, not the adapters. If guidance seems to belong in a harness
  file, it belongs in `docs/` with a pointer instead.
- New skills go in `skills/` following `skills/README.md`, and must pass
  `scripts/validate-skills.sh`.
- Facts borrowed from the outside world (model names, harness paths, vendor
  behaviors) carry a `Last verified:` date. Refresh them when you touch the file.
- Every doc is readable on its own. Link liberally; summarize, never duplicate.

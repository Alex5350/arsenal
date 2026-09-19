# Superpowers (methodology layer)

Last verified: 2026-09. [Superpowers](https://github.com/obra/superpowers)
is Jesse Vincent's open-source (MIT) skill framework: a complete software
development methodology for coding agents, shipped as composable skills and
installed per harness through native plugin distribution.

## Policy: reference and pin

Arsenal does not vendor Superpowers. It records, on this page, the version
the team has validated and the install command per harness. Bump the pin
deliberately (a PR that edits this file), never casually.

**Pinned version: latest upstream, validated 2026-09. Pin an exact release
in your consumer repo when you first install.**

## Install matrix

| Harness | Command |
| --- | --- |
| Claude Code | `/plugin marketplace add obra/superpowers-marketplace` then `/plugin install superpowers@superpowers-marketplace` |
| Codex CLI | `/plugins` in the TUI, search "superpowers", install |
| Codex App | Plugins sidebar (official OpenAI marketplace) |
| GitHub Copilot CLI | `copilot plugin marketplace add obra/superpowers-marketplace` then `copilot plugin install superpowers@superpowers-marketplace` |
| OpenCode | ask the agent to fetch and follow `.opencode/INSTALL.md` from the Superpowers repo |
| Cursor | `/add-plugin superpowers` in agent chat |
| Gemini CLI | `gemini extensions install https://github.com/obra/superpowers` |

## What it provides (and the loop uses)

brainstorming, writing-plans, executing-plans, test-driven-development,
systematic-debugging, verification-before-completion, subagent-driven
development, dispatching-parallel-agents, requesting-code-review,
receiving-code-review, using-git-worktrees, finishing-a-development-branch.

Mapping to the loop: `brainstorming` and `writing-plans` power
[planning](../workflows/02-planning.md); TDD, worktrees, and plan execution
power [execution](../workflows/03-execution.md); the review skills power
[verification](../workflows/04-verification.md).

## What arsenal adds on top

Superpowers stops at the end of a development branch. The gaps it
deliberately leaves to teams, and that this hub fills:

- tiered model routing across providers ([models/routing.md](../models/routing.md))
- work tracking across GitHub, Jira, Azure DevOps ([integrations/](../integrations/README.md))
- publishing and release discipline ([workflows/06-publishing.md](../workflows/06-publishing.md))
- team standards and their CI enforcement ([standards/](../standards/README.md))

If a future Superpowers release absorbs one of these, prefer the upstream
skill and shrink the hub; reference beats duplication.

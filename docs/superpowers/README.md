# Superpowers (methodology layer)

Last verified: 2026-09. [Superpowers](https://github.com/obra/superpowers)
is Jesse Vincent's open-source (MIT) skill framework: a complete software
development methodology for coding agents, shipped as composable skills and
installed per harness through native plugin distribution.

## Policy: reference and pin

Arsenal does not vendor Superpowers. It records, on this page, the version
the team has validated and the install command per harness. Bump the pin
deliberately (a PR that edits this file), never casually.

**Pinned version: 6.3.0.** Validated 2026-09-19: Claude Code 2.1.278 and
Codex 0.155.1 on 6.3.0 (via `superpowers@claude-plugins-official`), Copilot
CLI on 6.4.1 (via `superpowers@superpowers-marketplace`), OpenCode on
upstream main via the git plugin reference. 6.4.1 is upstream at the time
of writing. Pin an exact release in your consumer repo.

## Install matrix

| Harness | Command |
| --- | --- |
| Claude Code | `/plugin install superpowers@claude-plugins-official` (Anthropic's official marketplace), or `/plugin marketplace add obra/superpowers-marketplace` then `/plugin install superpowers@superpowers-marketplace` |
| Codex CLI | `/plugins` in the TUI, search "superpowers", install (`superpowers@claude-plugins-official`) |
| Codex App | Plugins sidebar (official OpenAI marketplace) |
| GitHub Copilot CLI | `copilot plugin marketplace add obra/superpowers-marketplace` then `copilot plugin install superpowers@superpowers-marketplace`; verify with `copilot skill list` |
| OpenCode | add `"plugin": ["superpowers@git+https://github.com/obra/superpowers.git"]` to `~/.config/opencode/opencode.json` (create it with `"$schema": "https://opencode.ai/config.json"` if absent; OpenCode 2.0.4+ names the key `plugins`); verify with `opencode debug skill` |
| Cursor | `/add-plugin superpowers` in agent chat |
| Gemini CLI | `gemini extensions install https://github.com/obra/superpowers` |

The two marketplace ids, `superpowers@superpowers-marketplace` (obra's own)
and `superpowers@claude-plugins-official` (Anthropic's official marketplace),
install the same `obra/superpowers` plugin; the official one may lag a
release behind. The OpenCode git reference installs upstream main on first
run; the upstream `.opencode/INSTALL.md` is the place to check when that
harness changes.

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

# OpenCode

Last verified: 2026-09.

## What it reads first

`AGENTS.md` (native), plus `opencode.json` at the repository root, which
this repo ships wired to the hub: it merges `docs/README.md` into
instructions and defines the tier agents.

## How skills reach it

Project skills: `.opencode/skills/<skill-id>/SKILL.md`. Here
`.opencode/skills` is a committed symlink to `docs/skills`, so the library
is discoverable the moment the repo is cloned; `scripts/bootstrap.sh`
verifies and repairs the link.

## Role agents

OpenCode loads custom agents from `.opencode/agent/<name>.md` (markdown,
frontmatter `description` plus optional `mode`/`model`/`tools`, body as the
system prompt) or `~/.config/opencode/agent/`. Here `.opencode/agent`
carries committed per-file symlinks to
[`docs/agents/`](../agents/README.md): researcher, planner, reviewer.

## Model tiers

`opencode.json` defines named agents with a model each. The shipped shape:

- `build` (primary): executor model, full tools
- `plan`: strategist model, read-leaning, used for planning and review

The shared role-agent files omit the `model` key (its value format is
per-harness); pin models in `opencode.json` or copy a role into a local
agent file with a `model` override when you want it bound. Set the model
ids to your pinned picks from `docs/models/routing.md`; the committed file
uses clearly-marked placeholder ids so nothing silently spends the wrong
budget. OpenCode can use any provider configured in its providers section,
which is the whole point of routing by role here.

## Gates

OpenCode runs the make targets through its shell tool; its permission
system can require confirmation for network commands, which usefully slows
down anything the security standard would question.

## Quirks worth knowing

- Agents, commands, and skills are three different extension points; this
  repo uses skills for procedural knowledge and `opencode.json` agents only
  for tier routing.
- Config schema lives at opencode.ai/docs; if a key renames, fix this file
  and the routing table, not the policy.
- Superpowers for OpenCode installs by fetching `.opencode/INSTALL.md` from
  the Superpowers repo; see [docs/superpowers/](../superpowers/README.md).

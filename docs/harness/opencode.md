# OpenCode

Last verified: 2026-09.

## What it reads first

`AGENTS.md` (native), plus `opencode.json` at the repository root, which
this repo ships wired to the hub: it merges `docs/README.md` into
instructions and defines the tier agents.

## How skills reach it

OpenCode reads project skills from `.agents/skills/<skill-id>/SKILL.md`
natively. Here `.agents/skills` is the canonical library, a real folder, so
it is discoverable the moment the repo is cloned, with no setup;
`opencode debug skill` lists the five (OpenCode 1.18.31). If a release
stops finding them (issue
[#41213](https://github.com/anomalyco/opencode/issues/41213) did on
1.18.15), the fallback is a `skills.paths` entry in the committed
`opencode.json` pointing at the same folder.

## Role agents

OpenCode loads custom agents from `.opencode/agent/<name>.md` or
`~/.config/opencode/agent/`, or from `agent` entries in `opencode.json`. It
does not read `.claude/agents` and has no setting for another agent path,
so here `opencode.json` defines researcher, planner, and reviewer as
subagents whose `prompt` is `{file:./.claude/agents/<name>.md}`, with the
`description` repeated verbatim from that file's frontmatter (contract:
[`docs/agents/`](../agents/README.md)). Nothing is copied: the canonical
markdown is read at load time, and `opencode debug agent <name>` shows it
resolved. The three-line YAML header arrives inside the prompt as plain
text; harmless, since `name` and `description` are stated in the entry.
`scripts/sync.sh --check` fails CI when an entry's description stops
matching the agent frontmatter, so edit the agent file first and the entry
second.

## Model tiers

`opencode.json` defines named agents with a model each. The shipped shape:

- `build` (primary): executor model, full permissions
- `plan` (primary): strategist model, read-leaning (`edit` denied,
  `git push*` denied), used for planning and review

The file follows the current schema: `model` is one string,
`provider/model`, and `permission` replaces the deprecated `tools` key. The
previous shape failed schema validation, so OpenCode would not start; fixed
2026-09-19.

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
  repo uses skills for procedural knowledge and `opencode.json` agents for
  tier routing plus the three role-agent pointers.
- Config schema lives at opencode.ai/docs; if a key renames, fix this file
  and the routing table, not the policy.
- Superpowers for OpenCode installs by fetching `.opencode/INSTALL.md` from
  the Superpowers repo; see [docs/superpowers/](../superpowers/README.md).

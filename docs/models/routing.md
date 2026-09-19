# Model routing

Last verified: 2026-09. Model names drift; the policy does not. Re-verify the
picks quarterly against your harness's model list before changing this file.

## The policy: route by role, not by brand

Three tiers, one principle: spend expensive tokens where they change
outcomes (deciding what to build and catching what is wrong), and cheap
tokens on volume work (writing and refactoring code that a plan already
defines).

| Tier | Role | Used for | Selection criteria |
| --- | --- | --- | --- |
| **Strategist (S)** | plan and judge | research, planning, code review verdicts, release notes, escalations | strongest reasoning and instruction-following available; cost is secondary because volume is low |
| **Executor (E)** | build | implementation, refactors, test authoring, mechanical migration, tracker updates | strong coding at low cost and latency; will run most of the tokens |
| **Reviewer (R)** | verify | diff review, test evidence audit, failure triage | careful reading and skepticism; mid-to-strong tier; must differ from the author session when possible |

Escalation rules:

- Executor stuck twice on the same task goes back to the strategist with a
  written account of both attempts.
- Reviewer findings that the executor disputes go to the strategist, with
  both cases written down.
- Anything touching security, money, or irreversible actions: strategist
  tier plus a human, always.

## Current picks (2026-09 snapshot)

Frontier names as of this writing, for orientation only; pin your own in the
consumer repo:

| Tier | OpenAI | Anthropic | Google |
| --- | --- | --- | --- |
| Strategist | GPT-5.6 Sol | Claude Opus 5 | Gemini 3.1 Pro |
| Executor | GPT-5.6 | current mid-tier (check `/model`) | Gemini 3.6 Flash |
| Reviewer | GPT-5.6 | Claude Fable 5 / mid-tier | Gemini 3.1 Pro |

Do not treat a table row as a permanent truth: providers rename and reprice
quarterly. The `Last verified` date above is the contract.

## Wiring per harness

The roles ship as shared agent definitions in
[docs/agents/](../agents/README.md) (researcher, planner, reviewer),
reaching each harness through its own door. The executor tier is your main
session in any harness. What follows is how each harness casts models into
those roles.

**Claude Code.** `/model` sets the session tier; subagents declare their own
`model:` field, so a plan-review subagent can run the strategist while the
main session stays executor. Set both once per project and let the
[skills](../skills/README.md) reference them by role. Agent Teams lead and
worker agents follow the same split: lead S, workers E, reviewer agent R.

**Codex CLI.** `model` in `~/.codex/config.toml` is the default (executor).
Run strategist sessions explicitly (`codex -m <strategist-model>`) for
planning and review passes; keep approval mode on for anything outbound.

**OpenCode.** `opencode.json` at the repo root defines named agents with a
model each: `plan` runs the strategist, `build` runs the executor. This
repository ships that file wired to the hub.

**GitHub Copilot.** The model is per-session in the chat model picker;
org policy can pin defaults. Keep strategist models for planning and review
chats, executor models for agent-mode implementation, per
[the Copilot guide](../harness/copilot.md).

## Why not one model for everything

Single-model routing is simpler and strictly worse: you either pay frontier
prices for mechanical edits or get mechanical judgment on architecture.
The tier split is the entire point of the harness: it lets the plan say
"executor does this task" and any harness translate that into the right
model invocation.

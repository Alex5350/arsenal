# Shared skills library

Last verified: 2026-09 against the [Agent Skills](https://agentskills.io)
specification.

Skills are the unit of reusable procedural knowledge: a folder with a
`SKILL.md` that any skills-compatible harness (Claude Code, Codex CLI,
OpenCode, Copilot, Cursor, Gemini CLI, and the rest of the 40+ adopters)
loads on demand. One copy here serves every harness on the machine; see
[ADR-002](../ARCHITECTURE.md).

## The library

| Skill | Phase | Does |
| --- | --- | --- |
| [`research-loop`](research-loop/SKILL.md) | research | fan out sub-agents, converge on a cited findings doc |
| [`planner-executor-handoff`](planner-executor-handoff/SKILL.md) | planning | write a standalone plan and hand it to an executor session |
| [`test-gate`](test-gate/SKILL.md) | verification | run both suites, triage failures, record evidence |
| [`work-tracking`](work-tracking/SKILL.md) | tracking | mirror work to GitHub, Jira, or Azure DevOps |
| [`release-publish`](release-publish/SKILL.md) | publishing | cut a release with notes, tag, artifacts, verification |

These five cover the loop's phases. The methodology inside planning and
execution (TDD, worktrees, subagent development) comes from
[Superpowers](../superpowers/README.md); these skills are the connective
tissue Superpowers deliberately leaves to each team.

## Authoring rules

1. **Frontmatter**: `name` (kebab-case, 64 chars max) and `description`
   (1024 chars max). The description is the trigger: state what the skill
   does and when to use it, in third person, with concrete cues ("Use when
   the user asks to..."). A skill that never fires or always fires has a
   bad description.
2. **Progressive disclosure**: `SKILL.md` stays under ~200 lines. Depth goes
   in `references/*.md`, executable helpers in `scripts/`, loaded only when
   the skill activates.
3. **Standalone**: a session with only the SKILL.md loaded must be able to
   follow it. Link out; do not assume.
4. **Portable**: no harness-specific syntax in the body. Harness differences
   live in [docs/harness/](../harness/README.md), referenced by path.
5. **Validated**: `scripts/validate-skills.sh` must pass; CI enforces it.

To add a skill: copy the shape of an existing one, write the description
last (it is the hardest part), and validate:

```bash
scripts/validate-skills.sh
```

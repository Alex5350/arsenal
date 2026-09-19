# 02 Planning

Owner: **strategist tier**. Skills: [`planner-executor-handoff`](../skills/planner-executor-handoff/SKILL.md),
Superpowers `brainstorming` and `writing-plans`.

## Entry criteria

Research findings, or an approved request small enough to skip research
explicitly (say so in the plan).

## Artifact

`docs/plans/<slug>.md` in the consumer repo:

```
# <plan title>
Work item: <tracker id>
## Goal and non-goals
## Context          (links to research, incidents, prior plans)
## Tasks            (each: acceptance criteria + how it will be tested + assigned tier)
## Test plan        (what the test gate will run)
## Risks            (each with its mitigation and owner)
## Rollback         (what makes this change safe to revert)
```

Tasks are sliced so an executor can finish one, fully green, in a single
session. A task that cannot be finished in a session is two tasks.

## Handoff contract

The plan is the complete input to the executor tier. It must stand alone:
no verbal context, no "as we discussed". If the executor needs it, the plan
carries it.

## Gate: plan approved

A human or a second strategist session reviews the plan against the research
and rejects it for: wrong problem, untestable acceptance criteria, missing
rollback, or tasks sliced for reviewer convenience instead of executor
success. Approval is recorded on the work item before any code is written.

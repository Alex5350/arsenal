---
name: planner-executor-handoff
description: Write a standalone implementation plan as the strategist tier and hand it to an executor-tier session for implementation. Use when research or a request is ready to become code, when the user asks for a plan or an implementation approach, or when switching from a planning model to a coding model.
---

# Planner to executor handoff

Goal: produce a plan the executor tier can execute without ever talking to
the planner. The plan is the entire interface. Phase doc:
`docs/workflows/02-planning.md`; tier policy: `docs/models/routing.md`.

## The handoff contract

A handoff is complete when the executor needs nothing but the plan and the
repository: no verbal context, no "as discussed", no tribal memory.

## Procedure (planner)

1. Read the research artifact and the relevant code paths yourself; do not
   plan from summaries alone.
2. Write `docs/plans/<slug>.md`:

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

3. Slice tasks to finishable-in-one-session size. A task an executor cannot
   complete green in a session is two tasks.
4. Assign each task a tier. Most are executor; anything re-deciding
   architecture is strategist.
5. Get the plan approved (human or second strategist session) before any
   code exists. Approval is recorded on the work item.

## Procedure (executor)

1. Read the plan fully before the first command.
2. Execute tasks in order, TDD where applicable, committing per
   `docs/standards/git.md`.
3. Deviations: small ones proceed and get logged in the handoff note; scope
   changes stop and go back to the planner as a work-item comment.
4. Hand back: diff, green gates, deltas from plan, what the reviewer should
   probe.

## Rules

- The planner does not implement; the executor does not re-plan. Crossing
  that line is how responsibility blurs and defects hide.
- If the executor is stuck twice on one task, it goes back to the planner
  with both attempts written down. That is a planning defect until proven
  otherwise.

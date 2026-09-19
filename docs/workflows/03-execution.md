# 03 Execution

Owner: **executor tier**. Skills: Superpowers `executing-plans`,
`test-driven-development`, `using-git-worktrees`, `subagent-driven-development`.

## Entry criteria

An approved plan ([02](02-planning.md)) and a work item in the tracker.

## Method

1. Create a branch and a [worktree](https://git-scm.com/docs/git-worktree)
   named for the work item. Parallel executors never share a checkout.
2. Work one task at a time, in plan order. TDD where the Superpowers skill
   applies: failing test, smallest change, refactor.
3. Commit per the [git standard](../standards/git.md) as tasks complete;
   every commit builds and passes `make test-unit`.
4. When all tasks are done: run both gates, summarize deltas from the plan
   (there are always deltas; unexplained ones are rejections), and open the
   verification request.

## Executor boundaries

- The executor implements the plan. Scope changes, discovered mid-task, go
  back to the strategist as a comment on the work item, not into the diff.
- The executor does not self-approve. Verification is a different tier
  ([04](04-verification.md)) precisely so the author never grades own work.
- Secret handling follows the [security standard](../standards/security.md);
  when in doubt, stop and ask.

## Exit artifact

A worktree diff, green local gates, and a handoff note on the work item:
what was built, what deviated from the plan and why, what the reviewer
should probe.

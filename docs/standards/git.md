# Git standard

## Branches

- One branch per work item, named `<tracker>-<id>-<slug>`: `gh-142-rate-limiter`,
  `jira-PROJ-7-import-map`, `ado-9831-export-job`.
- Long-lived branches beyond the default branch need a reason that survives
  being written down.
- Parallel agents work in separate [worktrees](https://git-scm.com/docs/git-worktree),
  never in one shared checkout.

## Commits

Conventional Commits only:

```
<type>(<scope>): <imperative summary>

type: feat | fix | docs | refactor | test | chore | ci | perf
```

Rules:

- The summary line is imperative and specific: "fix: reject expired upload
  tokens in refresh path", never "fix bug" or "updates".
- One logical change per commit. If you cannot describe it in one line, split it.
- Commit messages may be generated; commit *content* is always reviewed by the
  reviewer tier before merge.
- Never rewrite published history on shared branches. Fix-forward instead.

## History honesty

- History must reflect what actually happened. No backdating, no cosmetic
  rebases that hide mistakes, no empty commits to look busy.
- Fixup commits during review are fine; squash them before merge so each
  merged commit is buildable and passes tests.

## Pull requests

- Small enough to read in one sitting. If not, the plan was sliced wrong;
  re-slice.
- Description states: what changed, why, how it was tested, the work-item ID,
  and any risk the reviewer should probe.
- Merged only when CI is green and the reviewer tier has approved; see
  [code review](code-review.md).

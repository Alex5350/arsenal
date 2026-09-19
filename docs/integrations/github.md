# GitHub Issues backend

Last verified: 2026-09.

Setup: the `gh` CLI, authenticated (`gh auth login`). `GH_REPO` (`owner/repo`)
in `.env` names the repository; when it is unset, the script derives it from
`git remote get-url origin` (both `https://github.com/o/r.git` and
`git@github.com:o/r.git` forms) and fails only when neither is available.

## What the script calls underneath

| Command | Maps to |
| --- | --- |
| `work-item.sh create "Summary" --body ... --type story\|task\|bug` | `gh issue create --label <type>`; a missing label is created with `gh label create` and the call retried once |
| `work-item.sh comment <n> "..."` | `gh issue comment` |
| `work-item.sh transition <n> done` (or `closed`) | `gh issue close` |
| `work-item.sh transition <n> backlog` (or `open`, `reopened`) | `gh issue reopen` |
| `work-item.sh transition <n> "<other state>"` | `gh issue edit --add-label <state>` (spaces become `-`, so `in review` is `in-review`); the label is created on demand as for `create` |
| `work-item.sh link <n> <url>` | cross-reference comment |
| `work-item.sh pr <n> "Title" [--body ...] [--base <branch>]` | `gh pr create --title "gh-<n> Title"`, body ending in `Closes #<n>`, base `main` unless `--base` says otherwise; then adds the `in-review` label |
| `work-item.sh show <n>` | `gh issue view --json number,title,state,labels`, printed as one line: `#<n> <state> [labels] title` |

## Mapping loop states to GitHub

GitHub Issues have two states, so the middle states live in labels:

| Loop state | Representation |
| --- | --- |
| backlog | open, no label |
| ready | open, `ready` |
| in progress | open, `in-progress` + branch `gh-<n>-<slug>` |
| in review | open, `in-review` + an open PR linked to the issue (`work-item.sh pr` opens it with `gh-<n>` in the title and `Closes #<n>` in the body) |
| done | issue closed: by the PR's closing keyword on merge, or by `transition <n> done` when it did not; `show <n>` confirms |
| released | release notes reference the issue |

Use GitHub Projects for boards; the labels project cleanly onto any board
column configuration.

## Notes

- The Copilot coding agent works natively against issues: assign it an
  issue, it reads `AGENTS.md`, and its PR carries the gate evidence.
- Prefer `gh pr view --json` checks over reading chat claims; CI check
  status is the [test gate](../../.agents/skills/test-gate/SKILL.md) evidence.

# GitHub Issues backend

Setup: the `gh` CLI, authenticated (`gh auth login`), with `GH_REPO` set to
`owner/repo` in `.env` (or inherited from the checkout's origin).

## What the script calls underneath

| Command | Maps to |
| --- | --- |
| `work-item.sh create "Summary" --body ... --type bug` | `gh issue create` (bug adds the `security`-agnostic `bug` label if present) |
| `work-item.sh comment <n> "..."` | `gh issue comment` |
| `work-item.sh transition <n> closed` | `gh issue close` / `gh issue reopen` (open/closed are GitHub's only states) |
| `work-item.sh link <n> <url>` | cross-reference comment |

## Mapping loop states to GitHub

GitHub Issues have two states, so the middle states live in labels:

| Loop state | Representation |
| --- | --- |
| backlog | open, no label |
| ready | open, `ready` |
| in progress | open, `in-progress` + branch `gh-<n>-<slug>` |
| in review | open PR linked to the issue (`gh-<n>` in the PR title) |
| done | issue closed by the PR (closing keyword) |
| released | release notes reference the issue |

Use GitHub Projects for boards; the labels project cleanly onto any board
column configuration.

## Notes

- The Copilot coding agent works natively against issues: assign it an
  issue, it reads `AGENTS.md`, and its PR carries the gate evidence.
- Prefer `gh pr view --json` checks over reading chat claims; CI check
  status is the [test gate](../skills/test-gate/SKILL.md) evidence.

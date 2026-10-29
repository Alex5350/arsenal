---
name: work-tracking
description: Create, comment on, transition, link, and show work items in GitHub Issues, Jira, or Azure DevOps, and open the review pull request against one, so the tracker always matches reality. Use when starting any unit of work, at every loop phase transition, when opening a PR, and when asked to file, update, close, or check a ticket or issue.
---

# Work tracking

Goal: the tracker is the heartbeat, not a diary. If work happened, the
tracker says so, in the same session. Phase doc: `docs/workflows/05-tracking.md`.

## Mechanics

One command, three backends (configured via `.env`, shape in
`docs/templates/work-item.example.env`):

```bash
scripts/work-item.sh create   "Summary" --body "Context" [--type bug|task|story]
scripts/work-item.sh comment  <id> "What changed and the evidence"
scripts/work-item.sh transition <id> "<state>"
scripts/work-item.sh link     <id> <url>
scripts/work-item.sh pr       <id> "Title" [--body "..."] [--base <branch>]
scripts/work-item.sh show     <id>
```

`pr` opens the review pull request with the ID stamped in the title and the
backend's closing reference in the body (`Closes #<id>`, the Jira key, or
`AB#<id>`); it needs the `gh` CLI on every backend. `show` prints the item's
current state on one line: run it before claiming a state.

Backend selection: `WORK_BACKEND=gh|jira|ado` in `.env`. Per-backend setup:
`docs/integrations/`.

## State mapping

| Loop event | Tracker action |
| --- | --- |
| question accepted | create item, state backlog |
| plan approved | transition to ready, link the plan doc |
| execution starts | transition to in progress; branch named `<tracker>-<id>-<slug>` |
| verification requested | `pr` opens the review PR (on GitHub it also labels the issue `in-review`; on Jira and Azure DevOps transition to in review yourself); comment the handoff note |
| gate verdict | comment evidence; the item stays open until the PR merges |
| PR merged | `show` confirms done/closed (GitHub closes the issue from the PR body); `transition <id> done` if it did not |
| published | comment the release link; transition to released/closed |

Adapt the state names to the backend's workflow once and record the mapping
in `docs/workflows/05-tracking.md` of the consumer repo.

## Rules

- One unit of work, one item, one branch. No item, no branch.
- IDs are stamped in branch names, commits, and PR titles.
- Comments are short and factual: state changes, evidence links, verdicts.
  The tracker is an interface, not a transcript.
- Only update states you can prove: `show <id>` is the proof. A tracker
  claiming "done" on a red gate manufactures confidence and is a worse
  failure than no tracking.

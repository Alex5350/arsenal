---
name: work-tracking
description: Create, comment on, transition, and link work items in GitHub Issues, Jira, or Azure DevOps so the tracker always matches reality. Use when starting any unit of work, at every loop phase transition, and when asked to file, update, close, or check a ticket or issue.
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
```

Backend selection: `WORK_BACKEND=gh|jira|ado` in `.env`. Per-backend setup:
`docs/integrations/`.

## State mapping

| Loop event | Tracker action |
| --- | --- |
| question accepted | create item, state backlog |
| plan approved | transition to ready, link the plan doc |
| execution starts | transition to in progress; branch named `<tracker>-<id>-<slug>` |
| verification requested | transition to in review; comment the handoff note |
| gate verdict | comment evidence; on approval transition to done |
| published | comment the release link; transition to released/closed |

Adapt the state names to the backend's workflow once and record the mapping
in `docs/workflows/05-tracking.md` of the consumer repo.

## Rules

- One unit of work, one item, one branch. No item, no branch.
- IDs are stamped in branch names, commits, and PR titles.
- Comments are short and factual: state changes, evidence links, verdicts.
  The tracker is an interface, not a transcript.
- Only update states you can prove. A tracker claiming "done" on a red gate
  manufactures confidence and is a worse failure than no tracking.

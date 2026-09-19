# 05 Tracking

Owner: **executor tier**, continuously. Skill:
[`work-tracking`](../skills/work-tracking/SKILL.md). Backends:
[GitHub Issues, Jira, Azure DevOps](../integrations/README.md).

## The rule

If work happened, the tracker says so. The tracker is not a diary written at
the end; it is the heartbeat. Every phase transition in this loop is mirrored
in the same session that caused it.

## State mapping

| Loop state | Tracker state | Trigger |
| --- | --- | --- |
| question accepted | backlog / to do | research opens |
| research done, plan drafting | in progress | planning opens |
| plan approved | ready / approved | plan gate passes |
| execution underway | in progress | first commit on the work-item branch |
| verification requested | in review | handoff note posted |
| test gate green, PR merged | done / closed | merge lands |
| published | released | tag and notes exist |

Map to your backend's workflow states once, in the consumer repo, and keep
the mapping in this table.

## Mechanics

- One command, three backends: `scripts/work-item.sh create|comment|transition|link`.
  Configuration shape: `docs/templates/work-item.example.env`.
- IDs are stamped everywhere: branch names, commit messages, PR titles
  ([git standard](../standards/git.md)).
- Comments are short and factual: what changed state, evidence link, verdict.
  The tracker is an interface, not a transcript.

## Honesty

A tracker that says "in progress" on merged work, or "done" on red gates, is
worse than no tracker: it manufactures confidence. Agents update states they
can prove and leave the rest to humans.

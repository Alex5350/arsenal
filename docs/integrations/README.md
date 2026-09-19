# Work tracking integrations

Three backends, one contract. Phase docs and skills never call `gh`, `jira`,
or `az boards` directly; they call `scripts/work-item.sh`, which dispatches
to the configured backend. Swapping trackers is a config change, not a
rewrite.

| Backend | Requires | Guide |
| --- | --- | --- |
| GitHub Issues | `gh` CLI, authenticated | [github.md](github.md) |
| Jira | API token (REST via curl) or MCP server | [jira.md](jira.md) |
| Azure DevOps | `az` CLI with boards extension | [azure-devops.md](azure-devops.md) |

Selection: `WORK_BACKEND=gh|jira|ado` in `.env` (shape:
[`templates/work-item.example.env`](../templates/work-item.example.env)).
Never commit `.env`; see the [security standard](../standards/security.md).

## Choosing a backend

- Already on GitHub: use `gh`. Zero extra infrastructure; the coding agent
  and CI live there anyway.
- Jira shop: REST-via-token keeps agents off the UI license question; the
  MCP server is the better path when you also want read models in chats.
- Azure DevOps: `az boards` matches shops where pipelines and boards are the
  system of record.

All three store the same artifacts the loop produces: one item per unit of
work, state transitions mirroring [phase changes](../workflows/05-tracking.md),
evidence comments, and links to plans and releases.

# Azure DevOps backend

Setup: the `az` CLI with the `azure-devops` extension
(`az extension add --name azure-devops`), authenticated
(`az login`), plus `.env` with `ADO_ORG`
(`https://dev.azure.com/<org>`), `ADO_PROJECT`, and optionally
`ADO_AREA_PATH`.

## What the script calls underneath

| Command | Maps to |
| --- | --- |
| `create` | `az boards work-item create` (task or bug) |
| `comment` | `az boards work-item update --discussion` (append) |
| `transition` | `az boards work-item update --state` |
| `link` | `az boards work-item relation add` (hyperlink) |

## Mapping loop states

Azure Boards states are process-template-specific (Agile: New, Active,
Resolved, Closed; Scrum: New, Approved, Committed, Done). Use whatever your
process defines; record the mapping in the consumer repo's tracking doc as
[the workflow requires](../workflows/05-tracking.md). IDs in branch names
look like `ado-9831-import-job`.

## Notes

- Boards and Pipelines in one place is the reason to pick this backend:
  the [publishing phase](../workflows/06-publishing.md) can trigger
  `az pipelines run` with the same work-item ID trail.
- `az boards` handles auth via the CLI's token; no PATs in `.env`, which is
  one less secret to rotate than the Jira backend.
- Work item discussion appends are visible in the web UI verbatim; keep
  gate evidence trimmed to the useful lines.

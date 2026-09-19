# Jira backend

Last verified: 2026-09.

Setup: `.env` carries `JIRA_HOST` (for example `acme.atlassian.net`),
`JIRA_EMAIL`, `JIRA_TOKEN` (API token from id.atlassian.com), and
`JIRA_PROJECT` (project key). The script uses the REST API via `curl` and
builds every JSON body with `jq`; no local Jira CLI to install.

## What the script calls underneath

| Command | Maps to |
| --- | --- |
| `create` | `POST /rest/api/3/issue` (summary, ADF description; Task, Bug, or Story type) |
| `comment` | `POST /rest/api/3/issue/<key>/comment` (ADF body) |
| `transition` | `GET .../transitions`, match by name, then `POST .../transitions` |
| `link` | remote link (`POST .../remotelink`) |
| `pr` | `gh pr create --title "<KEY> Title"`, body ending with the key on its own line (needs the `gh` CLI: the code lives on GitHub) |
| `show` | `GET /rest/api/3/issue/<KEY>?fields=summary,status`, printed as `<KEY> <status> summary` |

State names (To Do, In Progress, In Review, Done) are workflow-specific;
`work-item.sh transition` reads your project's transitions at runtime and
picks the one whose transition name or target status name equals the
requested state, case-insensitive, so it accepts human state names.

## Notes

- The `Last verified: 2026-09` surface here is REST v3 with basic auth
  (email + API token). If Atlassian changes auth (as it has before), fix
  this backend only; nothing else in the hub knows Jira exists.
- MCP alternative: a Jira MCP server (declared per harness, for example
  `mcp_servers` in Codex's config or `.vscode/mcp.json`) is the better fit
  when you want query-style access in chats; the script remains the write
  path for agents.
- Descriptions and comments are sent as ADF (Atlassian Document Format)
  built with `jq`, one paragraph per non-empty line, so newlines and quotes survive
  the trip. Evidence pasted as separate lines reads as separate lines.

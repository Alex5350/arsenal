# Jira backend

Setup: `.env` carries `JIRA_HOST` (for example `acme.atlassian.net`),
`JIRA_EMAIL`, `JIRA_TOKEN` (API token from id.atlassian.com), and
`JIRA_PROJECT` (project key). The script uses the REST API via curl; no
local Jira CLI to install.

## What the script calls underneath

| Command | Maps to |
| --- | --- |
| `create` | `POST /rest/api/3/issue` (summary, description; task or bug type) |
| `comment` | `POST /rest/api/3/issue/<key>/comment` |
| `transition` | transition id lookup, then `POST .../transitions` |
| `link` | remote link (`POST .../remotelink`) |

State names (To Do, In Progress, In Review, Done) are workflow-specific;
`work-item.sh transition` resolves your project's transition ids at runtime,
so it accepts human state names.

## Notes

- The `Last verified: 2026-09` surface here is REST v3 with basic auth
  (email + API token). If Atlassian changes auth (as it has before), fix
  this backend only; nothing else in the hub knows Jira exists.
- MCP alternative: a Jira MCP server (declared per harness, for example
  `mcp_servers` in Codex's config or `.vscode/mcp.json`) is the better fit
  when you want query-style access in chats; the script remains the write
  path for agents.
- Description bodies are plain text; the script does not attempt ADF
  markup. Evidence pastes as preformatted text, which survives.

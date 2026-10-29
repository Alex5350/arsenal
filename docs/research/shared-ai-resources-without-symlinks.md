# Can one folder of AI resources serve Claude Code, Codex, and Copilot on Windows and macOS without symlinks?

Date: 2026-09-18 | Versions: Claude Code 2.1.277, Codex CLI 0.155.1, Copilot CLI
1.0.86 (VS Code docs dated 2026-09-16), OpenCode 1.18.31 | Sources consulted:
vendor docs and source listed inline; the repository itself (`git ls-files -s`,
`scripts/bootstrap.sh`).

## Findings

### Today's layout

The repository commits 13 symlinks (`git ls-files -s | grep -c '^120000'`): 4
skills directory links to `docs/skills` and 9 per-file agent links to
`docs/agents` (`.claude/agents`, `.opencode/agent`, `.github/chatmodes`).
Instructions already need no symlinks: `CLAUDE.md` uses `@` imports,
`AGENTS.md` is read natively elsewhere, `opencode.json` lists instruction files.

### Why symlinks fail on Windows

- Git for Windows defaults `core.symlinks` to `false`; symlinks then check out
  as text files holding the target path. Real symlinks need Developer Mode or
  admin rights. ([gitforwindows.org/symbolic-links](https://gitforwindows.org/symbolic-links),
  [git core.symlinks](https://github.com/git/git/blob/master/Documentation/config/core.adoc))
- Git Bash `ln -s` deep-copies by default unless
  `MSYS=winsymlinks:nativestrict`, so `scripts/bootstrap.sh` (five `ln -s`
  calls, no `MSYS` setting) would create copies on Windows.
  ([msys2.org/docs/symlinks](https://www.msys2.org/docs/symlinks/))
- Real folders and text config files need no Windows setup.

### Skills: where each tool looks (project level)

| Folder | Claude Code | Codex CLI | Copilot (CLI / VS Code / cloud) | OpenCode |
| --- | --- | --- | --- | --- |
| `.claude/skills` | yes | **no** | yes / yes / yes (cloud: medium) | yes |
| `.agents/skills` | **no** | yes | yes / yes / yes | yes |
| `.github/skills` | no | no | yes | no |
| `.codex/skills` | no | yes (legacy, undocumented) | no | no |
| Committed config key that adds a folder | none (plugin only) | none (plugin only) | none that all surfaces honor | `skills.paths` in `opencode.json` |

Sources: Claude Code [memory](https://code.claude.com/docs/en/memory) ("Not
read: ... anything under a `.agents/` directory"),
[skills](https://code.claude.com/docs/en/skills), issue
[#80801](https://github.com/anthropics/claude-code/issues/80801) (shared
`.agents/` closed not planned 2026-09-18); Codex
[build-skills](https://learn.chatgpt.com/docs/build-skills) and
`codex-rs/ext/skills/src/host_roots.rs` (`[[skills.config]]` only toggles
skills on or off); Copilot
[about-agent-skills](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills),
[VS Code agent skills](https://code.visualstudio.com/docs/copilot/customization/agent-skills);
OpenCode [skills](https://opencode.ai/docs/skills).

**Key fact:** Claude Code and Codex share no skills folder, and neither offers
a committed config key to add one. Every single-source layout therefore needs
exactly one bridge for skills, to either Claude Code or Codex.

### Skills found in two folders

- Copilot CLI: "first found wins for duplicate names", project order
  `.github/skills` > `.agents/skills` > `.claude/skills`
  ([CLI reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference)).
  1.0.68 fixed parse errors from symlinked scan roots
  ([changelog](https://github.com/github/copilot-cli/blob/main/changelog.md)).
- VS Code: keeps the first skill per name, skips the rest silently
  ([vscode#317940](https://github.com/microsoft/vscode/issues/317940), fixed by
  PR #320695, 2026-06-09).
- Copilot cloud agent: no source covers it (unknown).
- OpenCode: logs a duplicate-name warning
  ([#46327](https://github.com/anomalyco/opencode/issues/46327)); cosmetic.

### Agents

| Location | Claude Code | Codex | Copilot (CLI / VS Code / cloud) | OpenCode |
| --- | --- | --- | --- | --- |
| `.claude/agents/*.md` | yes | no (TOML only) | yes / yes / undocumented | no |
| `.github/agents/*.agent.md` | no | no | yes / yes / yes | no |
| `.codex/agents/*.toml` | no | yes; `[agents.<n>] config_file` may point elsewhere | no | no |
| `opencode.json` `agent` entries | no | no | no | yes, prompt via `{file:...}` |

`.chatmode.md` is legacy in VS Code (rename to `.agent.md`). Codex agents are
TOML-only, so a generated file is unavoidable for Codex whatever the layout
(bootstrap already generates it). Sources: Claude
[sub-agents](https://code.claude.com/docs/en/sub-agents); Codex
[subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents);
GitHub
[custom-agents-configuration](https://docs.github.com/en/copilot/reference/custom-agents-configuration);
OpenCode [agents](https://opencode.ai/docs/agents) and issue
[#14240](https://github.com/anomalyco/opencode/issues/14240) (no agent path key,
closed not planned).

### Instructions and MCP

- `AGENTS.md` is read natively by Codex, Copilot (all surfaces), and OpenCode.
  Claude Code reads it only as a fallback when no `CLAUDE.md` exists, and not
  on Bedrock, Vertex, or Foundry, with telemetry off, or under
  `disableAllHooks` ([memory](https://code.claude.com/docs/en/memory)). The
  current `CLAUDE.md` with `@` imports is the documented Windows-safe route.
- MCP has no shared standard yet (SEP-2633 is a draft). `.mcp.json` covers
  Claude Code, Copilot CLI, and VS Code's Agent Host; Codex needs
  `.codex/config.toml` `[mcp_servers]` (trusted projects); OpenCode needs the
  `mcp` key. The repository has no MCP config today, so this is future work.

## Confidence

High for the per-tool paths (docs and source agree, two independent research
passes). What would change the answer:

- Claude Code reading `.agents/skills` (open issue
  [#26489](https://github.com/anthropics/claude-code/issues/26489)): the
  standard folder would then need no bridge at all.
- Codex adding a skill-path config key or reading `.claude/skills`.

## Open questions

1. Resolved: Copilot CLI and VS Code deduplicate a skill found in two folders
   by name; see "Skills found in two folders". Copilot cloud agent behavior is
   unknown; the generated mirror is byte-identical, so either copy is correct.
2. OpenCode [#41213](https://github.com/anomalyco/opencode/issues/41213):
   skills in `.claude`/`.agents` silently not found on 1.18.15. Fallback:
   `skills.paths` in the committed `opencode.json`.
3. Copilot cloud agent reading `.claude/agents`: undocumented.
4. The Claude Code repo-local plugin route is documented piecemeal, never
   end to end. Not pursued (see Decision).

Questions 2 and 3 become tracked work items with the implementation.

## Recommendation

No layout gives 100% native, symlink-free sharing across Claude Code and Codex
today, because they share no skills folder and neither accepts a configured
one. The best available layout makes `.claude/skills` and `.claude/agents` the
real canonical folders: Claude Code, Copilot, and OpenCode then read them with
no setup on any OS. Codex gets one bridge for skills, either a committed
generated mirror in `.agents/skills` checked by CI (zero symlinks, fully
Windows-safe, but a copy) or a single symlink (one copy, but Windows Codex
users need Developer Mode). The alternative, `.agents/skills` as canonical, is
the cross-tool standard, but its only symlink-free bridge to Claude Code is a
repo-local plugin that the docs label development-only, that needs a trust
prompt per user, and that never loads in headless runs. That moves the
canonical home out of `docs/` and contradicts ADR-002, so it needs an explicit
decision before any restructure.

## Decision

2026-09-18: canonical skills and agents move to `.claude/skills` and
`.claude/agents`. Codex is bridged by a committed generated mirror in
`.agents/skills`, regenerated by a sync command and checked for drift in CI
(option A). ADR-002 is superseded accordingly.

## Decision (revised 2026-09-19)

Supersedes the 2026-09-18 decision. The canonical skills folder is the
cross-tool `.agents/skills`, the only skills folder in the repository; role
agents stay in `.claude/agents`. Claude Code reaches the skills through a
committed repo-local plugin (`.claude-plugin/plugin.json`,
`.claude-plugin/marketplace.json`, `.claude/settings.json`). No symlinks, no
skill copies; the only generated files are `.codex/agents/*.toml`. Open
question 4 is thereby resolved: the plugin route was tested end to end.

Tested 2026-09-19 with Claude Code 2.1.278, Codex 0.153.2, Copilot CLI
1.0.86, and OpenCode 1.18.31, on this repository:

- Claude Code: with the plugin loaded, the debug log shows
  `Loaded 5 skills from plugin arsenal custom path: <repo>/.agents/skills`
  and the model lists them as `arsenal:<name>`; skills are invoked as
  `/arsenal:<skill>`. The repo settings register the plugin only after the
  teammate accepts the folder trust prompt (one prompt per teammate per
  repo; Anthropic settings docs). In a trusted checkout the first session
  (interactive or `claude -p`) registers the marketplace in place
  (`installLocation` is the repo path; nothing is copied to a cache) but
  does not load its skills yet; from the second session on, every session,
  headless `claude -p` included, loads the five skills. The only case that
  needs `claude -p --plugin-dir .` is a checkout where no earlier session
  has run: a fresh machine or a CI runner. Adopting the template means
  renaming `arsenal` in three files (`plugin.json` name, `marketplace.json`
  name and plugin name, `settings.json` keys).
- Codex: `codex debug prompt-input` lists the repository's `.agents/skills`
  as a skill root with all five skills. Agents: `.codex/agents/*.toml`,
  trusted projects only.
- Copilot CLI: `copilot skill list` shows the five under "Project skills";
  `copilot instruction list` shows `copilot-instructions.md`, `AGENTS.md`,
  and `CLAUDE.md`. Copilot reads `.claude/agents` per GitHub's docs; no CLI
  listing exists to confirm it, so open question 3 stands.
- OpenCode: `opencode debug skill` lists the five from `.agents/skills`;
  `opencode debug agent <name>` resolves researcher, planner, and reviewer
  with the markdown loaded through `{file:./.claude/agents/<name>.md}`
  prompts (the three-line YAML header is included as text). A pre-existing
  bug was fixed on the way: the old `opencode.json` failed OpenCode's schema
  (`model` must be one `provider/model` string; `permission` replaces the
  deprecated `tools`), so OpenCode would not start. Open question 2
  ([#41213](https://github.com/anomalyco/opencode/issues/41213)) keeps its
  fallback: add `skills.paths` to `opencode.json` if a release stops
  reading `.agents/skills`.
- Fresh clone with `core.symlinks=false` and `core.autocrlf=true`: 0
  symlinks, 0 CR bytes, all files present; `claude plugin validate --strict .`
  passes.

Costs accepted: the `arsenal:` name prefix in Claude Code, the trust prompt,
and `--plugin-dir .` for checkouts with no prior session. Rejected: symlinks
(Windows checkouts turn them into text files) and a generated copy of the
skills (a sync step after every edit, a drift check, and duplicate names in
the harnesses that scan both folders). Open question 1 is moot with one
folder.

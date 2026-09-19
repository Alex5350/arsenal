# TECHNICAL.md

For the engineer inheriting this repository. The why of the design lives in
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) as short decision records; this
file is the operating manual: layout, contracts, and how to extend.

## Layout

```
AGENTS.md                     universal entry every harness reads
CLAUDE.md                     Claude Code adapter (@imports docs/)
.github/copilot-instructions.md   Copilot adapter
opencode.json                 OpenCode config: tier agents wired to the hub
.claude/skills -> ../docs/skills   } each harness's project skills
.codex/skills  -> ../docs/skills   } directory, committed as a relative
.opencode/skills -> ../docs/skills } symlink to the one canonical library
.github/skills -> ../docs/skills   }
docs/                         the hub (single source of truth)
scripts/                      bootstrap, validators, work-item dispatcher
Makefile                      make verify = the same checks CI runs
```

## The adapter contract

| File | Harness | Mechanism | Last verified |
| --- | --- | --- | --- |
| `AGENTS.md` | Codex CLI, OpenCode, Copilot coding agent; Claude Code fallback | read natively | 2026-09 |
| `CLAUDE.md` | Claude Code | `@path` imports pull `docs/README.md` + the Claude guide | 2026-09 |
| `.github/copilot-instructions.md` | Copilot in VS Code | prompt prepending; defers to AGENTS.md | 2026-09 |
| `opencode.json` | OpenCode | instructions merge + named tier agents | 2026-09 |

Rule: adapters carry no guidance. If you find yourself adding rules to an
adapter, add them to `docs/` and link instead.

## Skill pipeline

1. Canonical source: `docs/skills/<name>/SKILL.md` (Agent Skills standard:
   `name` + `description` frontmatter, progressive disclosure).
2. Each harness's project skills directory (`.claude/skills`, `.codex/skills`,
   `.opencode/skills`, `.github/skills` for Copilot) is a committed relative
   symlink to `docs/skills`, so every harness's native skill discovery
   resolves to the one library. A fresh clone works with zero setup, and the
   Copilot coding agent sees the same skills on github.com.
3. `scripts/bootstrap.sh` verifies and repairs those links (including
   Windows checkout placeholders) and, with `--user`, links the skills into
   `~/.claude/skills`, `~/.codex/skills`, and `~/.copilot/skills` for your
   other projects.
4. `scripts/validate-skills.sh` enforces the authoring rules (frontmatter,
   kebab-case name matching the directory, description 20 to 1024 chars,
   non-empty body). CI runs it; so does `make verify`.

Adding a harness means one line in the bootstrap mapping table, a committed
relative symlink, and a guide in `docs/harness/`; see the playbook there.

## Script contracts

| Script | Exit 0 means | Exit 1 means |
| --- | --- | --- |
| `validate-skills.sh` | every SKILL.md conforms | at least one violation, listed |
| `check-links.sh` | all relative md links resolve | broken links listed as file:line |
| `bootstrap.sh` | project links verified/repaired (plus user wiring with `--user`) | misuse or missing docs/skills |
| `work-item.sh` | tracker operation succeeded | backend error with remediation hint |

`work-item.sh` dispatches on `WORK_BACKEND` (`gh`, `jira`, `ado`), loads
`.env` at the repo root if present, and is the only sanctioned caller of
`gh` / Jira REST / `az boards` in the whole loop. Backends implement
`create`, `comment`, `transition`, `link`; the Jira backend speaks REST v3
with an ADF-paragraph body, the Azure backend shells to `az boards`, the
GitHub backend shells to `gh`.

## CI design

Two jobs, `validate` and `gitleaks`:

- `validate`: bash syntax pass, skill frontmatter, internal links, and
  shellcheck on every script.
- `gitleaks`: full-history secret scan on every push and PR.

Deliberate choices:

- No runtime toolchain (no Node/Python/.NET): a stack-agnostic template
  must prove itself with what every runner already has. See ADR-004.
- Actions pinned by full commit SHA, per the security standard. Refresh
  deliberately: `gh api repos/<owner>/<repo>/git/ref/tags/<tag>`.
- Consumer repositories get their gate from `docs/templates/app-ci.yml`,
  which runs `make test-unit` and `make test-integration` per the testing
  standard.

## Extending

**Add a skill**: `docs/skills/<name>/SKILL.md`, description written last
(it is the trigger); `make verify`; PR per the PR template.

**Add a tracking backend**: implement the four subcommands in
`scripts/work-item.sh` (pattern: `<backend>_<op>` functions plus dispatch),
add `.env` keys to `docs/templates/work-item.example.env`, write
`docs/integrations/<backend>.md`, update the integrations table.

**Add a harness**: entry file (prefer the existing `AGENTS.md`), bootstrap
mapping line, `docs/harness/<tool>.md` answering the five questions, matrix
updates in the harness README and root README.

## Local workflow

```bash
make verify      # everything CI checks
make bootstrap   # wire skills into detected harnesses (--dry-run first)
```

## Known limitations

- Windows checkouts without `core.symlinks` materialize the four skills
  symlinks as text files; run `scripts/bootstrap.sh` from a POSIX shell
  (Git Bash) to repair them.
- Harness skill paths and provider model names are the two fastest-drifting
  facts; both carry `Last verified` dates and live in single places (the
  bootstrap mapping table, `docs/models/routing.md`).
- The hub governs through instructions and CI; in-session enforcement beyond
  harness permissions and hooks is out of scope by design.
- `work-item.sh` Jira descriptions flatten newlines (plain ADF paragraph);
  multiline ADF would buy nothing the loop needs.

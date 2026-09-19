# Glossary

Plain-language definitions for the terms this repository uses. When a term appears
capitalized in the docs, it means what it means here.

| Term | Definition |
| --- | --- |
| **Harness** | The loop that runs a model: tool dispatch, context management, permissions, verification. Claude Code, Codex CLI, OpenCode, and GitHub Copilot are each a harness. Harnesses are interchangeable by design in arsenal; the hub does not depend on any one of them. |
| **Agent** | A model running inside a harness, working toward a goal with tools (shell, file edits, web requests). |
| **Subagent** | An agent spawned by another agent to do scoped work (research a question, review a diff) and report back. Subagents can run a different model than the parent, which is how tiered routing executes in practice. |
| **Adapter** | A thin root file that points one harness at `docs/`: `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`, `opencode.json`. Adapters never carry guidance of their own. |
| **Agent Skill** | A folder with a `SKILL.md` file (plus optional scripts, references, assets) that packages procedural knowledge for any skills-compatible agent. Open standard: agentskills.io. Loaded by progressive disclosure: the agent sees name and description first, full instructions only when a task matches. |
| **AGENTS.md** | The open, tool-agnostic instruction file read by Codex CLI, OpenCode, and the Copilot coding agent natively, and by Claude Code as a fallback. Arsenal's AGENTS.md is the universal entry point. |
| **MCP (Model Context Protocol)** | An open protocol for connecting agents to external tools and data (for example a Jira or Azure DevOps server). Used where a CLI or REST call is not enough. |
| **Plugin** | A distributable package for a harness: skills, hooks, commands, sometimes MCP servers. Superpowers ships as a plugin for many harnesses. |
| **Tier** | A role in the model routing policy. **Strategist (S)** plans, researches, and reviews. **Executor (E)** writes and refactors code. **Reviewer (R)** verifies diffs and test evidence. See `docs/models/routing.md`. |
| **Handoff** | The controlled transfer of work from one tier or agent to another, always with a written artifact: a plan, a diff, or a test report. |
| **Test gate** | The exit criteria of a phase: unit and integration suites green, evidence recorded. Work does not move forward through a red gate. |
| **Work item** | One trackable unit of work: a GitHub Issue, a Jira issue, or an Azure DevOps work item. Every task in the loop maps to exactly one. |
| **The loop** | Arsenal's six-phase delivery cycle: research, planning, execution, verification, tracking, publishing. Defined in `docs/workflows/`. |
| **Worktree** | A detached git working tree used to run multiple agents on separate tasks in one repository without them touching each other's files. |
| **Drift** | The tendency of external surfaces (model names, harness paths, vendor docs) to change under you. Every borrowed fact in this hub carries a last-verified date so drift is detectable. |

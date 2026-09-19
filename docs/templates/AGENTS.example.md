# AGENTS.md starter for consumer repositories

Copy to the repository root (replacing the arsenal version) when you create a
repo from the arsenal template, then fill the bracketed parts. Keep it short:
the hub carries the standards; this file carries what is unique to your repo.

---

# AGENTS.md

You are a coding agent working in **[product name]**, a [one-line description]
built with [stack]. The working method comes from the arsenal hub:
read `docs/README.md` first if it is present.

## What this repository is

[Two or three sentences: the product's purpose and its users.]

## Project-specific rules

- [The one or two rules that differ from hub defaults, for example: "all
  public API changes update docs/api.md in the same PR".]

## Commands

| Task | Command |
| --- | --- |
| Run unit tests | `make test-unit` |
| Run integration tests | `make test-integration` |
| [Run the app locally] | `[command]` |
| [Lint] | `[command]` |

## Tracking

Backend: [gh | jira | ado], configured per docs/templates/work-item.example.env.
Stamp work-item IDs in branches, commits, and PRs per the hub's git standard.

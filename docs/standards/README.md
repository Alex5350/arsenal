# Standards

The non-negotiables. These apply to every harness, every tier, every task.
Where a phase doc and a standard disagree, the standard wins.

| Standard | One-line contract |
| --- | --- |
| [Git](git.md) | Conventional commits, work-item-stamped branches, honest history |
| [Testing](testing.md) | Unit and integration gates green before any handoff, no skips |
| [Security](security.md) | No secrets in the repo; agent actions least-privilege by default |
| [Code review](code-review.md) | Every diff read by a reviewer tier before merge |
| [Documentation](documentation.md) | Docs change with code; borrowed facts carry verify dates |

## Why standards live in the hub

A standard that lives in one harness's config governs one tool. The same
standard written once in `docs/` and imported by every adapter governs the
team. When a rule changes, it changes here, and every harness sees the new
rule on its next session.

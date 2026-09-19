# Code review standard

Every diff is read before merge. The reviewer may be a reviewer-tier model, a
human, or both. A model review never lowers the bar; it raises the floor.

## What the reviewer checks, in order

1. **Plan conformance**: does the diff do what the plan said, nothing more?
   Scope creep goes back.
2. **Tests**: does the change carry tests that fail without it? Are the gates
   actually green (evidence, not claims)?
3. **Correctness**: read every changed line. Models and humans alike must
   actually read; approving on file names is not review.
4. **Security**: new inputs validated, no secrets, permissions unchanged
   unless intended. See [security](security.md).
5. **Maintainability**: names, dead code, comment noise. Comments explain
   constraints, not narration.
6. **Docs**: user-visible or architectural changes updated the docs in the
   same PR. See [documentation](documentation.md).

## Reviewing AI-authored diffs

- Assume nothing about the author's intent; the diff is the entire argument.
- Watch for confident adjacent changes: renamed variables, "improved" error
  messages, touched files nobody asked about. Each one needs its own
  justification.
- Watch for tests that mock the thing under test.
- Run the suite yourself if the evidence seems too tidy.

## Etiquette

- Findings are about the code, phrased so the next reader learns something.
- Blocking findings say what would make them pass.
- Approvals are recorded on the PR with the work-item ID; see
  [tracking](../workflows/05-tracking.md).

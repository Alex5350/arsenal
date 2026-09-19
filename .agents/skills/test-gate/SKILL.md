---
name: test-gate
description: Run the unit and integration suites, verify nothing was skipped, triage failures, and record merge-blocking evidence on the work item. Use before any handoff from execution to review, when asked to verify a change or run the tests, or when a pull request claims to be green.
---

# Test gate

Goal: replace "should work" with exit codes on record. Phase doc:
`docs/workflows/04-verification.md`; standard: `docs/standards/testing.md`.

## Procedure

1. **Clean checkout.** Run the gates where stale state cannot flatter you:
   fresh clone or clean CI runner.
2. **Run both gates and capture exit codes:**

```bash
make test-unit
make test-integration
```

3. **Verify nothing was skipped.** Skipped, pending, or deleted tests fail
   the gate even with exit 0. Diff the test list against the branch base if
   the framework does not report skips loudly.
4. **Triage failures on the ladder:**
   - flaky: rerun once; passing once means quarantine plus a work item, and
     the gate stays red until fixed
   - environment: prove it (missing service, wrong version), then fix the
     environment, then rerun
   - real: back to execution with the failing case attached
5. **Record evidence** on the work item: trimmed gate output, skip count,
   findings, verdict (`approved` or `rejected: <what would flip it>`).

## Rules

- The gate is run by someone who did not write the change whenever possible;
  author-run gates are provisional.
- Exit codes are the interface. Suite output parsing, frameworks, and stacks
  are the consumer repo's business.
- Never widen a gate to let work through. A waived gate is a written human
  decision with a reason and an owner, recorded on the work item.

## Quick reference

| Check | Passes when |
| --- | --- |
| unit suite | `make test-unit` exit 0 |
| integration suite | `make test-integration` exit 0 |
| skip audit | zero skipped or deleted tests |
| evidence | output and verdict posted on the work item |

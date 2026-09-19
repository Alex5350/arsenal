# 04 Verification

Owner: **reviewer tier** (a reviewer-class model, a human, or both).
Skill: [`test-gate`](../skills/test-gate/SKILL.md).

## Entry criteria

An execution handoff: diff, plan, and the claim that local gates are green.

## Method

1. Re-run the gates yourself in a clean checkout. Claims are not evidence;
   `make test-unit` and `make test-integration` exit codes are.
2. Review the diff against the plan using the [code review standard](../standards/code-review.md).
   Read every changed line.
3. Triage failures with the ladder:
   - flaky: rerun once; if it passes, quarantine with a work item (still red
     until fixed)
   - environment: prove it (missing service, wrong version), then fix CI
   - real: back to execution with the failing case attached
4. Record evidence on the work item: gate outputs (trimmed), findings,
   verdict.

## Gate: test gate green

The merge-blocking gate passes only when both suites exit 0, nothing was
skipped or deleted to get there, and findings are either fixed or waived in
writing by a human with a reason. See the [testing standard](../standards/testing.md).

## Exit artifact

A verdict on the work item: approved with evidence, or rejected with failing
cases and what would flip the verdict.

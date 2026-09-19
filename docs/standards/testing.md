# Testing standard

## Definitions

- **Unit test**: exercises one module in isolation, no network, no database,
  no clock. Fast enough that hesitation to run it is a bug report about the
  test suite.
- **Integration test**: exercises real seams: database, HTTP, file system,
  message queue. Uses real engines where possible (for example Postgres, not a
  mock that claims to be Postgres). May be slower; runs on every PR.
- **End-to-end test**: drives the product the way a user does. Few, stable,
  owned. E2E suites that flake get quarantined and fixed, not ignored.

## The contract

Every consumer repository provides the same two entry points so agents and CI
never guess:

```bash
make test-unit          # exit 0 = pass; no network required
make test-integration   # exit 0 = pass; may spin up local services
```

Exit codes are the interface. Anything else (output format, framework, stack)
is the consumer repo's choice. The `docs/templates/app-ci.yml` starter runs
both on every pull request.

## The gate

Work moves from execution to tracking only when:

1. `make test-unit` and `make test-integration` both exit 0.
2. No test was skipped, marked pending, or deleted to achieve exit 0.
3. New behavior and fixed bugs carry a test that fails without the change.

A red gate stops the line. Fix the code, or fix a wrong test with an
explanation in the PR. "Temporarily" disabling a test is how "temporarily"
becomes "ever".

## Authoring rules

- Name tests after behavior: `rejects_expired_tokens`, not `test_1`.
- One assertion concept per test; failure output should localize the defect.
- Deterministic: freeze time, seed randomness, stub only what crosses the
  process boundary.
- If a test is flaky, quarantine it in a named list in CI with an owning work
  item, and it counts as a red gate until fixed.

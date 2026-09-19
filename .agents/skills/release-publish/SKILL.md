---
name: release-publish
description: Cut and publish a release with version bump, changelog notes, annotated tag, CI-built artifacts, and a post-release verification check. Use when verified work is ready to ship, when asked to release, publish, deploy, or cut a version, or when closing a delivery cycle.
---

# Release publish

Goal: ship what was verified, and prove it works from the outside. Phase
doc: `docs/workflows/06-publishing.md`. A human co-signs this phase, always.

## Checklist

1. **Version.** Bump per the consumer repo's policy (semver default).
   Breaking changes are major bumps; surprises are defects.
2. **Notes.** Write the changelog for the reader of the diff: what changed,
   why, what they must do. Generated notes are a draft; edit them. Reference
   the work-item IDs being closed.
3. **Tag.** Annotated tag on the merge commit:

```bash
git tag -a vX.Y.Z -m "Release vX.Y.Z: closes <work-item ids>"
git push origin vX.Y.Z
```

4. **Artifacts.** Everything consumers receive is built by CI and attached
   to the release, never built on a laptop.
5. **Publish.** Push through the consumer's channel: GitHub Release, package
   registry, `az pipelines run`, deployment. Use the same work-item ID
   trail so the release links back to its evidence.
6. **Verify from outside.** One concrete check that the published thing
   works as a consumer sees it: install it, hit the endpoint, run the smoke
   test. Record the result on the release work item.

## Rules

- No release without a green test gate behind it; link the evidence.
- No release notes that only a committer could parse.
- Rollback plan stated in the notes when the change touches runtime
  behavior.

## Close the loop

Within a day, file what the cycle taught: follow-ups, debt, new research
questions. That backlog is the next cycle's research input.

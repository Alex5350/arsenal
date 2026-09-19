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

   The tag push is what the release workflow listens for
   (`docs/templates/release.yml`, copied to
   `.github/workflows/release.yml` in the consumer repo): it reruns
   `make test-unit`, drafts notes from the Conventional Commits between the
   previous tag and this one, creates the GitHub Release, and runs the
   post-release check named in the `POST_RELEASE_CHECK` repository variable.
4. **Artifacts.** Everything consumers receive is built by CI and attached
   to the release, never built on a laptop (the build step in the workflow
   is the place).
5. **Publish.** Push through the consumer's channel: GitHub Release (the
   workflow's `gh release create`), package registry, `az pipelines run`,
   deployment. Use the same work-item ID trail so the release links back to
   its evidence.
6. **Verify from outside.** One concrete check that the published thing
   works as a consumer sees it: install it, hit the endpoint, run the smoke
   test. The workflow runs `POST_RELEASE_CHECK` when set; record the result
   on the release work item either way.

## Rules

- No release without a green test gate behind it; link the evidence.
- No release notes that only a committer could parse.
- Rollback plan stated in the notes when the change touches runtime
  behavior.

## Close the loop

Within a day, file what the cycle taught: follow-ups, debt, new research
questions. That backlog is the next cycle's research input.

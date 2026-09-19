# 06 Publishing

Owner: **strategist tier plus a human**. Skill:
[`release-publish`](../skills/release-publish/SKILL.md).

## Entry criteria

Merged, verified, tracked work that a consumer can receive: a versioned
artifact, a deployment, or a published document.

## Checklist

1. **Version**: bump per the consumer repo's policy (semver unless the repo
   says otherwise). Breaking changes are major bumps, not surprises.
2. **Notes**: changelog written for the reader of the diff: what changed,
   why, what they must do. Generated notes are a draft; the strategist edits.
3. **Tag**: annotated tag `vX.Y.Z` on the merge commit, pushed with the
   work-item IDs it closes referenced in the tag message.
4. **Artifacts**: build and attach what consumers receive (packages, images,
   bundles) from CI, never from a laptop.
5. **Publication**: push the release through the consumer's channel: GitHub
   Release, package registry, Azure DevOps pipeline, deployment.
6. **Post-release verification**: one concrete check that the published thing
   works from the outside (install it, hit it, run its smoke test). Record
   the result on the release work item.

## Gate

Publishing is the one phase a human always co-signs. Automation may prepare
everything; a person presses the button or approves the pipeline.

## Close the loop

Within a day of publishing, file what the cycle taught: follow-ups, debt
noticed during review, research questions the work raised. That backlog is
the input to the next cycle's [research](01-research.md) phase. The loop
ends by beginning.

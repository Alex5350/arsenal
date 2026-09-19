# 01 Research

Owner: **strategist tier**. Skill: [`research-loop`](../skills/research-loop/SKILL.md).

## Entry criteria

A question whose answer changes what gets built or how: a library choice, a
failure mode, a migration path, a security claim.

## Method

1. Decompose the question into 3 to 6 sub-questions small enough to answer
   with sources.
2. Fan out: one sub-agent or one search thread per sub-question. Parallel,
   not sequential; the harness supports this natively (subagents, tasks, or
   multiple sessions).
3. Each claim gets a source: official docs, the repository itself, a
   reproducible command's output. Mark inference as inference.
4. Converge: reconcile contradictions explicitly; "source A says X, source B
   says Y, the difference is version skew" beats a silent pick.

## Artifact

`docs/research/<slug>.md` in the consumer repo:

```
# <question>
Date | Sources consulted
## Findings        (each claim with its source)
## Confidence      (what would change this answer)
## Open questions  (each either resolved or converted to a task)
## Recommendation  (one paragraph, decision-ready)
```

## Exit gate

Every open question is either resolved or converted into a tracked work item.
Research that ends in "more research needed" without tracking it has failed.

## Anti-patterns

- One giant context-stuffed session instead of fanned-out sub-questions.
- Citing blog paraphrases when the primary source is reachable.
- Answering the question that was easy instead of the one that was asked.

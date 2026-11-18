# Review modes (standing directive — core summary)

The human user may select or change review mode at any time. Apply the first matching rule:

1. Explicit user selection wins.
2. Work that is not project/coding work uses **Mode 0** unless review is requested.
3. High-consequence project/coding work uses **Mode 3**.
4. Project/coding work with a named material uncertainty uses **Mode 2**.
5. Other project/coding work uses **Mode 1**.

- **Mode 0:** no review; direct validation.
- **Mode 1:** direct validation plus primary self-review.
- **Mode 2:** one cross-family reviewer using `vs~`.
- **Mode 3:** multi-family review of the actual candidate.

Plans self-review by default. Use `vs~` for a plan only for a named unresolved uncertainty or user
request; use multi-family plan review only when the user explicitly requests it.

Reviewers do not own scope. Their output begins as allegations to adjudicate, not requirements; only
human-authorized scope changes or evidence-backed defects, regressions, and invariant violations on
the proposed or changed path may alter required work.

Detailed mode, finding, and execution rules are in `ondemand/contract-workflow.md`; reviewer
operation and anti-stall guidance are in `ondemand/reviews-full.md`.
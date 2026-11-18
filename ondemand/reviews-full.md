<!-- loaded-on-demand: read before delegated review, a review-mode change, or a long reviewer invocation. CONTRACT.md §6 and ondemand/contract-workflow.md govern. -->
# Reviews — operational guide

Review exists to improve a decision. The selected mode, not file durability or technology labels,
determines the required review work. The human user may change mode at any time.

## Modes

- **Mode 0:** no review; direct validation only.
- **Mode 1:** primary self-review after validation.
- **Mode 2:** one cross-family reviewer using `vs~`.
- **Mode 3:** 2–4 reviewers from distinct families on the actual candidate.

Plans self-review by default. Use `vs~` for a plan only for a named unresolved uncertainty or user
request. Use multi-family plan review only when the user explicitly requests it.

## `vs~`

The reviewer inspects the actual artifact, scope, acceptance criteria, and validation. For each
candidate allegation:

1. the primary rebuts, concedes, or reframes it with evidence;
2. the reviewer counters once;
3. the primary adjudicates against the artifact.

Batch allegations when they fit safely; otherwise use complete deterministic batches. Permit one
material autonomous plan revision, then ask the user if material disagreement remains.

## Multi-family review

Use independent model families, not several variants or invocations from one family. Size or
effort variants of one model are one family. List the independent families available in your
environment in the machine or host file, not here.

Adapt to available models and disclose substitutions or reduced coverage. Do not pretend that
same-family calls provide family diversity.

Round 1 reviewers independently inspect the actual candidate through complementary lenses. Round 2
shows each reviewer the artifact and other reviewers' allegations for confirmation, refutation, or
re-grading. The primary then runs the bounded allegation-level exchange and adjudicates against
evidence. A clean review is valid.

Deeper defense rounds, rotation, advisors, and separate final reviewers are optional. Use them only
when requested or when the primary states a concrete decision they are expected to improve.

## Reviewer prompt contract

Ask reviewers to be skeptical, specific, and severity-calibrated. Each proposed blocker should name:

- the affected criterion or invariant;
- the changed-path mechanism;
- supporting evidence;
- proposed severity; and
- the smallest sufficient mitigation.

Reviewers do not own scope. Additional features, unrelated hardening, and pre-existing issues are
scope proposals, not blockers. Finding count, confidence, votes, persistence, and adversarial tone
are not evidence.

## Findings and revisions

Reviewer output begins as candidate allegations. The primary records confirmed, unresolved,
refuted, duplicate, resolved, and out-of-scope dispositions. Confirmed or credible unresolved
Critical/High risks retain their CONTRACT §7 consequences.

For Mode 3 candidate review, address the reconciled finding set in one coherent revision and review
the new candidate again. If another material cycle is needed, present the remaining findings and
options to the user instead of continuing autonomously.

## Transport and anti-stall

Use tracked background jobs for long reviewer invocations. Do not launch a bare detached `&` process
and promise a later response; it cannot notify the session. Reviewer CLIs may buffer output, so use a
pollable output file when the invocation can run long.

On Windows, agentic reviewer CLIs can derail when a prompt mentions external paths or commands. Use
one of these established approaches:

1. direct non-streaming API wrapper for verdict-style review;
2. auto-approve mode only for read-only review of trusted local artifacts; or
3. tools-off mode when the complete artifact is inline.

Follow the host-specific machine note for exact invocation details.

## Failure handling

Give a reviewer one initial invocation and one retry of the same model through another supported
route after a confirmed CLI or transport failure. If both fail, report the unavailable seat and ask
the user whether to substitute, continue with reduced coverage, change mode, or stop. Never loop
indefinitely or treat empty output as a clean review.

## Reporting

Report:

- selected mode and any user override;
- artifact and validation reviewed;
- reviewer families for Modes 2–3;
- confirmed findings, unresolved risks, refutations, and scope proposals;
- substitutions or unavailable seats; and
- SHIP, REVISE, or HUMAN REVIEW REQUIRED.
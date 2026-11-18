<!-- loaded-on-demand: read when using delegated review, changing review mode, or preparing a review artifact. CONTRACT.md §6 and §10 are authoritative. -->
# Engineering operating contract — review and execution procedure (§8, §9, §11)

## 8. Review-mode procedures

The human user may select or change review mode at any time. The primary agent may recommend a mode
by naming the specific uncertainty or consequence, but follows the user's decision without
relitigating it. Review is a tool for improving a decision, not a ceremony attached to durable work.

### Scope ownership and findings

At Stage 0, record a scope version containing the objective, acceptance criteria, and explicit
non-goals. Reviewers test that scope; only the human user may authorize a new version.

Every reviewer submission begins as a **candidate allegation with proposed severity**. The primary
agent adjudicates it as:

- a **confirmed in-scope finding** supported by the artifact or reproducible evidence;
- a **credible unresolved risk** after bounded investigation;
- **refuted, duplicate, resolved, or unsupported**; or
- a **scope proposal or unrelated pre-existing issue**.

Only confirmed findings require changes. Credible unresolved risks receive the §7 disposition for
their severity but do not expand scope automatically. Reviewers advise; the primary remains
accountable for adjudication.

### Mode 1 — self-review

After validation, inspect the actual result or diff against the scope and acceptance criteria. Check
for regressions, incomplete caller/documentation updates, accidental scope growth, unsafe behavior,
and validation gaps. Correct material issues and report the evidence. No delegated review artifact
is required.

### Mode 2 — `vs~`

Give one reviewer from a different model family the actual candidate, scope, acceptance criteria,
and relevant validation. Ask for skeptical, specific, severity-calibrated findings; a clean report
is valid.

For each candidate allegation, the primary provides an evidence-based rebuttal (defend, concede, or
reframe), the reviewer gives one counter, and the primary adjudicates against the artifact. Batch a
reviewer's allegations in one exchange when they fit safely; otherwise use complete deterministic
batches and omit none. Permit one material autonomous plan revision; unresolved material
disagreement goes to the user.

### Mode 3 — multi-family review

Use 2–4 reviewers from genuinely distinct model families on the actual candidate. Assign
complementary lenses appropriate to the work, such as correctness/architecture, security/abuse,
reliability/operability, and testing. Several variants or invocations from one family provide no
family diversity; size or effort variants of one model are one family.

Round 1 reviewers independently inspect the artifact. In round 2, each receives the artifact plus
the other reviewers' candidate allegations and attempts to confirm, refute, or re-grade them with
evidence. Then run the bounded allegation-level rebuttal/counter/adjudication exchange used by
`vs~`. Deeper or rotational formats are optional and used only when the user requests them or the
primary states a concrete reason they are likely to change the decision.

Separate plan advisors, in-flight advisors, final reviewers, and Engineering Decision Records are
optional additions. Selecting Mode 3 alone does not select them.

### Reviewer quality and independence

- Give reviewers the actual artifact, not only a narrative summary.
- Require a changed-path mechanism, evidence, severity rationale, and smallest sufficient mitigation.
- Do not reward finding count, severity, persistence, confidence, votes, or adversarial tone.
- Preserve dissent in the findings ledger, but decide against evidence rather than reviewer identity.
- A reviewer may recommend a mode change; only the user changes the mode.

### Reviewer families and transport

The independent families available depend on the environment and are listed in the machine or host
file. Adapt to available models and report substitutions or
limitations rather than pretending that several same-family calls are independent.

Give a reviewer one initial invocation and, after a confirmed CLI/transport failure, one retry of
the same model through another supported route. If both fail, report the unavailable seat and let
the user decide whether to substitute, continue with reduced coverage, change mode, or stop. Do not
loop indefinitely.

Operational transport and anti-stall details are in `ondemand/reviews-full.md`.

## 9. Execute, validate, and review

### 9.1 Stage 0

State the objective, scope and non-goals, acceptance criteria, implementation stages, validation
strategy, selected review mode, and any material risk or rollback requirement. Depth scales with the
task. Plans self-review by default; Mode 2 plan review requires a named unresolved uncertainty or
user request, and multi-family plan review requires an explicit user request.

### 9.2 Implement

- Keep work aligned with the current scope version.
- Prefer one writer for one coherent change set; parallelize only independent ownership.
- Update affected callers, tests, documentation, and generated artifacts where the change requires.
- If evidence shows that the objective cannot be met safely inside scope, present the smallest
  choices to the user instead of silently expanding the task.

### 9.3 Validate

Run checks that exercise the changed behavior or operated surface. Do not claim a command, test,
deployment, migration, rollback, or review occurred unless it did. When a useful check is unavailable,
state what remains unverified and its practical consequence.

### 9.4 Apply the selected review mode

- **Mode 0:** direct validation only.
- **Mode 1:** direct validation, then primary self-review.
- **Mode 2:** direct validation and `vs~` on the actual candidate.
- **Mode 3:** direct validation and multi-family review on the actual candidate.

Finish ordinary implementation iteration and cleanup before invoking delegated candidate review.
If the candidate changes after a reviewer inspected it, rerun affected validation and the selected
candidate review against the new bytes. Optional advisors or final reviewers are refreshed only when
they were selected for the task.

### 9.5 Bounded revision

A material plan revision changes scope, acceptance criteria, validation, rollback, blast radius, or
remediation of a confirmed material finding. Editorial changes, duplicate findings, tool retries,
model substitutions, and context/session changes do not count.

Mode 2 planning permits one material autonomous revision. For Mode 3 candidate review, one coherent
revision may address the reconciled finding set before the candidate is reviewed again. If another
material cycle would be required, present the findings and options to the user. This limit never
clears a Critical/High finding or authorizes shipment.

### 9.6 Complete

Apply CONTRACT §10 using only the validation and review selected for the task. Missing optional
review machinery is not a defect. Report exactly what changed, what was verified, unresolved risks,
and the SHIP, REVISE, or HUMAN REVIEW REQUIRED recommendation.

## 11. Optional engineering decision record

Use a decision record when requested or when a consequential project decision benefits from a
durable rationale. Include: submitter, decision, scope/non-goals, evidence, validation results,
selected review mode and findings, risks, rollback/recovery, and recommendation. Do not create one
merely because work changed a durable file.
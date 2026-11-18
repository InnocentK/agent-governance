<!-- loaded-on-demand: read before substantial or multi-stage work, or when a handoff may be needed. -->
# Staged execution, handoffs, and compaction guardrail — full procedure

Purpose: keep results **repeatable even under heavy context use**. You cannot prevent compaction,
but you can control WHEN it happens (force it to a stage boundary, right after a fresh handoff) so
state always survives it. This is the mechanism that stops "compaction at a bad interval" from
silently degrading a long task.

## Stage 0 is always a plan

Every task begins with Stage 0: state the objective, bounded stages, selected review mode, validation
strategy, and material risk or rollback needs. An explicit user-selected mode wins. Depth scales
with the task; small Mode 0/1 work may use one sentence.

Plans self-review by default. A Mode 2 plan review requires a named unresolved uncertainty or user
request. Multi-family plan review requires an explicit user request. If one stage threatens the
context budget, split it before proceeding.

## The stage checklist

Track multi-part work and keep the current stage visible. The checklist is the resume pointer after
interruption or compaction.

```text
- [x] Stage 0  Plan + selected mode (Mode 1) — self-reviewed
- [x] Stage 1  <done> — validation recorded
- [ ] Stage 2  <in progress>  ← CURRENT
- [ ] Stage 3  <not started>
```

## Handoffs preserve substantial multi-stage work

Write or refresh a handoff at the end of a substantial multi-stage boundary, before likely
compaction, when work crosses harnesses, or when the user requests an audit artifact. Mode 0 and
small Mode 1 tasks require no handoff merely for ceremony. When a handoff is warranted, write it
before continuing so a later context can resume safely.

**Compaction is NOT automatic at every boundary.** Compact only when:

- the harness surfaces high usage (~≥80%),
- a near-limit signal appears, or
- the next stage plainly will not fit in the remaining budget.

Otherwise, keep working in the same context. (Verified: omp and opencode expose no live context-%;
codex exposes only absolute tokens used; Claude Code gives only a near-limit warning.)

**When you DO compact** (boundary + a high-usage/near-limit signal, or forced by overflow):
1. Refresh the handoff (schema below) and update the checklist current-stage marker.
2. Compact (`/compact`/`/handoff`, or start a fresh context).
3. **Resume from the handoff** — read it first thing in the new context, and verify its identity
   stamp matches the current repo/worktree/branch/commit (below) before acting on it.

## Handoff file location — OUT OF REPO (enables safe cleanup; no gitignore dependence)

Handoffs live **outside any repository**, so no per-repo gitignore is needed and an age-based cleanup
job can safely sweep them:

```
$XDG_STATE_HOME/ai-handoffs/<repo-slug>/<harness>/<task-slug>/current.md
   (fallback when XDG_STATE_HOME is unset: ~/.local/state/ai-handoffs/...)
```

- `<harness>` = your harness identity, a FIXED ALLOWLIST value: `claude` / `codex` / `opencode` /
  `omp` (matches `~/.ai-memory/tail/<tool>.md`; your tail file declares which you are). If your
  harness isn't one of these, use `other`. This is never free text.
- `<repo-slug>` / `<task-slug>` = the repo id (remote `group/proj` else toplevel basename) and task id
  (ticket/slug), each reduced to a **single safe slug**: keep `[A-Za-z0-9._-]`, replace every other
  character (including `/` and `\`) with `-`, collapse repeats, trim to ≤64 chars, and if the result
  is empty or begins with `-`/`.` prefix it with `id-`. (The slug is only a folder name; the
  authoritative identity lives in the handoff header below, so slug collisions are caught at resume by
  the header check, not relied on for correctness.)

**Path safety (keep it simple + robust):**
- Slugs contain only `[A-Za-z0-9._-]` and are single components by construction — so no `/`, `\`,
  `..`, or separators can appear. Reject the reserved device names (CON, PRN, NUL, COM1…, LPT1…).
- Resolve the state base as `$XDG_STATE_HOME`, defaulting to `~/.local/state` when it is unset,
  then append `/ai-handoffs` to get the handoff **root** (so the root is always
  `<state-base>/ai-handoffs`, both with and without `XDG_STATE_HOME`). Build the full path under
  that root and confirm the final path is a descendant of it. Refuse if the **state base**, the
  **`ai-handoffs` root**, OR **any descendant component** (repo-slug, harness, task-slug dirs) is a
  symlink/reparse point — check the whole chain, not just the leaf. Create dirs `700`, file `600`
  where the OS supports it.
- **Single active handoff = `current.md`, ATOMIC REPLACE** (write a temp file in the same dir, then
  `mv`/rename over `current.md`). Optionally archive a prior stage under `archive/`, but `current.md`
  is the one source of truth (never infer "current" from filename-sort).
- **Overwrite guard (slugs are lossy — a collision could clobber a different task's handoff):** before
  replacing an EXISTING `current.md`, read its identity header. If its repo id or task id differs from
  the current task (a slug collision landed two different tasks in the same folder), do NOT overwrite:
  disambiguate by appending a **stable** digest of the authoritative identity to the task-slug dir —
  the first 12 hex chars of `SHA-256("<repo-id>\n<task-id>")` (that exact newline-joined encoding, so
  the same task always derives the same suffix and re-finds its own handoff). Surface the collision to
  the user. If even the digest dir already holds a *different* identity (a rare secondary collision),
  fail closed: do not overwrite — surface it and stop. Only overwrite when the existing header's
  repo+task identity matches the current task (the normal same-task refresh case).
- **Single-harness only.** A handoff belongs to the harness that wrote it; do NOT resume from another
  harness's namespace (that removes any need to trust another harness's self-asserted state). If you
  switch harnesses mid-task, re-orient from the repo + the user, not from a sibling handoff.

**Identity stamp (required header, STRICT and MINIMAL alike):** repo id, worktree absolute path,
branch, current commit, **`dirty: yes|no`** (does `git status --porcelain` show anything), UTC
timestamp, writer harness, and status (`active` | `superseded` | `complete`).

**Resume safety — simple staleness check (no byte-exact hashing):** before acting on a handoff,
confirm the current environment matches its stamp: **`status: active` AND same repo id AND same
worktree path AND same branch AND same current commit.**
- All of those match AND the handoff was written `dirty: no` AND the tree is clean now → safe to
  resume directly.
- Any mismatch (different repo/worktree/branch/commit), OR `status` is `superseded`/`complete`/
  malformed/unknown, OR the handoff was `dirty: yes`, OR the tree is dirty now → do **NOT**
  blind-resume. Re-orient first: re-read the actual files/diff, reconcile against the handoff's
  stated decisions, and treat the handoff as a *guide to intent*, not as verified current state. If
  the mismatch is a different commit/branch than expected, surface it to the user before continuing.

Rationale for dropping byte-exact diff hashing + cross-harness resume: a reproducible content hash is
expensive to specify correctly (binary/rename/symlink/locale edge cases) and its only job is to say
"the tree changed" — which `dirty: yes` + a commit check answers conservatively. Cross-harness resume
required trusting another harness's self-asserted state; single-harness handoffs remove that trust
problem entirely. A changed tree or a foreign handoff simply means "re-orient, don't trust stale
decisions," which is the safe behavior we actually want, at a fraction of the spec complexity.

## Handoff hygiene

Handoffs are documentation and must not contain credential values. Prefer concise summaries over
raw command output when the output may contain credentials, and reference protected artifacts by
path instead of copying their contents. The out-of-repo location and user-only permissions reduce
accidental exposure but do not make credential values appropriate for the handoff.

## Handoff schema

**Substantial multi-stage work → STRICT schema (fill every field; "N/A" if truly empty):**

```markdown
# Handoff — <task-id> — Stage <n> (<short title>)  [status: active]
- **Identity:** repo=<repo-id> worktree=<path> branch=<b> current=<sha> dirty=<yes|no>
  ts=<UTC> writer=<harness>
- **Objective:** <the task's goal>
- **Acceptance criteria:** <how "done" is judged>
- **Selected review mode:** <Mode 0|1|2|3; user override or matched reason>
- **Decisions made:** <decisions + one-line rationale each>
- **Decisions rejected:** <alternatives considered and why not>
- **Files changed this stage:** <paths + one-line what/why — paths only, no contents>
- **Validation:** <command/scenario → sanitized outcome>
- **Current stage / next stage:** <where we are; what Stage n+1 does>
- **Open risks / unknowns:** <anything unverified or requiring a user decision>
- **Review status:** <self-review, vs~, multi-family, or optional advisor/final reviewer actually used>
```

**Small Mode 0/1 work → MINIMAL schema when a handoff is needed:**

```markdown
# Handoff — <task-id> — Stage <n>  [status: active]
- **Identity:** repo=<repo-id> worktree=<path> branch=<b> current=<sha> dirty=<yes|no>
  ts=<UTC> writer=<harness>
- **Plan (Stage 0):** <one-sentence plan and selected mode>
- **Done this stage:** <what changed + sanitized verification>
- **Next:** <next step, or "complete">
- **Open items:** <or "none">
```

A handoff is useful only when a later context can act without re-explanation. Prefer the strict
schema for substantial work; do not create a handoff for ordinary bounded work unless needed.

## Cleanup of old handoffs (schedule + plan)

Because handoffs are out-of-repo and (by the hygiene rule) non-sensitive, they can be swept on age:

- **Plan:** delete any `current.md`/archive older than **30 days** (mtime) under
  `$XDG_STATE_HOME/ai-handoffs/` (fallback `~/.local/state/ai-handoffs/`); prune emptied dirs. A
  handoff marked `status: complete` may be swept sooner (**15 days** — one sprint; completed work is
  still referenceable within the sprint, then reclaimed). Never touch anything outside that root. The
  sweep is idempotent and logs what it removed.
- **Schedule (SEPARATE apply step — spec only; install after user approval):**
  - Linux hosts: a user `cron`/systemd-timer running daily, e.g.
    `find "${XDG_STATE_HOME:-$HOME/.local/state}/ai-handoffs" -type f -mtime +30 -delete` then prune
    empty dirs. Pick an off-peak, non-:00 minute.
  - Windows: a Scheduled Task running an equivalent Git-Bash
    `find … -mtime +30 -delete`.
  - The actual job is NOT installed by this memory change — it is a follow-up apply step to spec and
    get user approval for (destructive-on-a-schedule → §5), then verify with a dry-run (`-mtime`
    listing) before enabling `-delete`.


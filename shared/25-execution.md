# Execution discipline (standing directive)

- **Stage 0 is always a plan.** State the objective, bounded stages, selected review mode, validation,
  and material risk or rollback needs. A genuinely small task may use one sentence.
- **User mode selection wins.** Mode 0 uses direct validation; Mode 1 adds self-review; Mode 2 adds
  `vs~`; Mode 3 adds multi-family review of the actual candidate.
- **Plans self-review by default.** Use delegated plan review only for a named unresolved uncertainty
  or explicit user request.
- **Track multi-part work.** Keep the current stage visible so work can resume after interruption.
- **Handoff when useful.** Write a handoff for reviewed or substantial multi-stage work, a likely
  context boundary, a harness switch, or a requested audit artifact. Do not create one for ordinary
  bounded work merely to satisfy ceremony.
- **Compact only when needed.** Refresh the handoff before compaction; otherwise continue in the same
  context.
- **Validate the changed surface.** Review depth never substitutes for exercising the behavior.

Full handoff, identity, resume, and cleanup procedure is in `ondemand/staged-execution.md`.
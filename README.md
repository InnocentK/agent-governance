# agent-governance

A governance model for working with AI coding agents: one operating contract and one
layered memory source that generate consistent instructions for several agent harnesses
(Claude Code, Codex, OpenCode, omp) on several machines.

This is the portable core of a system I designed and use daily. Environment-specific
material (machine facts, model routing, internal tooling, work records) has been removed,
and the machine files here are short examples to replace with your own.

## What is here

| Path | What it is |
|---|---|
| `CONTRACT.md` | The operating contract: evidence standards, scope discipline, approval boundaries, review modes, finding severity, completion criteria. Read at session start. |
| `shared/` | Short always-loaded rules, inlined into every generated instruction file. `00-router.md` maps concrete actions to the procedure that must be read first. |
| `ondemand/` | Longer procedures loaded only when the router says so: review workflow, reviewer operation, staged execution and handoffs, memory placement policy. |
| `machine/` | Facts scoped to an operating system (`windows.md`, `linux-common.md`) or one host (`hosts/<hostname>.md`). Examples only. |
| `tail/` | Per-harness extras. |
| `sync-memory.sh` | The generator. Checks target markers, scans the assembled output for credential values, and writes one instruction file per harness atomically. |
| `.githooks/pre-commit` | Blocks a commit that would add a credential value to the sources. |
| `drift-hook.snippet` | Optional shell-startup check that warns when generated files have drifted. |

## The ideas

- **Review depth is proportional.** Mode 0 is direct validation, Mode 1 adds self-review,
  Mode 2 adds one reviewer from a different model family, Mode 3 uses several families. The
  user can always choose the mode.
- **Reviewers allege; the primary agent adjudicates.** Reviewer output is checked against the
  artifact and evidence. Agreement between models is not evidence.
- **Humans own scope and risk.** A High finding can be accepted by the user. A Critical
  finding cannot: it is fixed or the work stops.
- **Always-loaded memory stays small.** Standing rules live in `shared/`. Procedures live in
  `ondemand/` and are reached through router rows phrased as actions ("BEFORE you…").
- **Sources are authoritative; generated files are disposable.** Never edit a generated
  instruction file. Edit the source and regenerate.

## Use

Clone to `~/.ai-memory`, then:

```bash
~/.ai-memory/sync-memory.sh --check    # report drift, write nothing
~/.ai-memory/sync-memory.sh --dry-run  # show what would change
~/.ai-memory/sync-memory.sh --write    # regenerate every target
git -C ~/.ai-memory config core.hooksPath .githooks
```

Generated targets (a fixed map, never globbed):

- claude → `~/.claude/CLAUDE.md`
- codex → `~/.codex/AGENTS.md`
- opencode → `~/.config/opencode/AGENTS.md`
- omp → `~/.omp/agent/AGENTS.md`

Each generated file is `shared/*.md` in sorted order, then the machine base for the detected
operating system, then the matching host file if one exists, then `tail/<tool>.md`, written
between `<!-- ai-memory:start -->` and `<!-- ai-memory:end -->` markers. Content outside the
markers that the generator does not own stops the run until it is migrated with
`--extract-tail`.

## Editing workflow

1. `sync-memory.sh --check` before editing; do not edit on top of unknown drift.
2. Edit the source here, never a generated file.
3. `sync-memory.sh --write`.
4. Commit the source. Git history is the audit trail and the rollback.

`ondemand/memory-organization.md` is the placement policy: what belongs in the always-loaded
core, what goes on demand, and the size budgets that keep the core from growing.

## Limits

- Most of this is instruction that a model has to follow. Only some controls are enforced in
  code (the generator's marker checks, the secret scans, atomic writes).
- The generator does not yet verify that every router row points at an existing procedure;
  that check is manual.
- The generator has been used on Windows (Git Bash) and Ubuntu.
- There is no automated test suite in this repository.

## How it was built

I designed the model and directed AI coding agents to implement and revise it, reviewing
and validating the results myself. Multi-model design reviews shaped several parts of the
generator; comments in `sync-memory.sh` cite the findings they address.

## License

Copyright 2026 Innocent Kironji. Licensed under the Apache License, Version 2.0; see `LICENSE`.

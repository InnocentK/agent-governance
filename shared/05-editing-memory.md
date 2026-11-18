# Editing global AI memory (standing directive — core summary)

The `~/.ai-memory/` sources are the **single source of truth** for shared AI-tool memory. The
per-tool files (`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.config/opencode/AGENTS.md`,
`~/.omp/agent/AGENTS.md`) are **generated** by `~/.ai-memory/sync-memory.sh`. **Never edit a
generated file directly** — edit the source, then regenerate.

**Edit workflow:**
1. `sync-memory.sh --check` — surface existing drift BEFORE editing; don't edit on top of unknown drift.
2. Edit the SOURCE in `~/.ai-memory/` (never a generated file).
3. `sync-memory.sh --write` — regenerate all targets.
4. Commit the source AS YOURSELF (git author = your harness name, for example
   `claude`, `codex`, `opencode` or `omp`). Attribution is tamper-EVIDENT, not tamper-proof; git history is the audit trail + rollback.

Applies to you, the AI tool, as much as to the user — including non-interactive `claude -p` /
`codex exec` runs that have the script available.

**Default: record global memories in `~/.ai-memory` (then regenerate), NOT in a tool's generated
file.** Prefer the shared source so every tool gets it; route to `tail/<tool>.md` only when genuinely
specific to one tool.

**BEFORE adding or editing memory, read `ondemand/memory-organization.md`** (via the Router). It is
the PLACEMENT + anti-bloat policy: core-vs-on-demand tiering, the "new tool → Router row + on-demand
doc, never inline into core" rule, the machine/host/tail placement rule, the core size budget, and
the post-edit self-audit. Following it is what keeps this memory from re-bloating.

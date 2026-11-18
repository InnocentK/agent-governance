<!-- loaded-on-demand: read BEFORE adding/editing anything in ~/.ai-memory (Router row: "ADD/EDIT anything in global memory"). Not inlined into always-loaded memory. Complements shared/05-editing-memory.md (the edit WORKFLOW); this file is the PLACEMENT / anti-bloat POLICY. -->
# Memory organization & anti-bloat policy

`~/.ai-memory` is largely maintained by AI agents. This policy keeps the always-loaded core SMALL
so every session doesn't start with a bloated context. Follow it whenever you add or edit memory —
including when the user says something casual like "add this to my global memory." Your job is to
file the addition correctly, NOT to dump it into always-loaded core.

`shared/05-editing-memory.md` covers the edit WORKFLOW (check drift → edit source → `sync-memory.sh
--write` → commit as yourself) and the machine-axis placement rule (shared vs machine vs host vs
tail). THIS file adds the **core-vs-on-demand tiering** and the anti-bloat rules.

## The three tiers

1. **CORE (always loaded)** — everything in `shared/*.md` is inlined into every generated file, so
   it costs context on EVERY session. Core is reserved for standing directives
   (independent judgment, scope/risk decisions, multi-task and staged-execution rules, review-mode
   selection), the **Router** (`shared/00-router.md`), and short summaries that point to on-demand
   docs. Core must stay small.
2. **ON-DEMAND (`ondemand/*.md`)** — detailed procedures, command surfaces, tool docs, worked
   examples. NOT inlined (the generator only reads `shared/`, `machine/`, `tail/`). Read on trigger
   via the Router. This is where depth lives.
3. **MACHINE / HOST / TAIL** — machine-specific paths/quirks and single-tool quirks (placement
   rule below).

## Machine-axis placement rule (route by WHERE it applies)

- **Truly cross-machine content** (applies identically on every machine and tool — standing
  directives, operating contract, review policy) → `shared/*.md` (core) or `ondemand/*.md` (detail).
- **OS-family content** (any machine of that OS, not the other) → the OS base file: `machine/windows.md`
  (single Windows box) or `machine/linux-common.md` (any Linux host).
- **Host-specific content** (this exact box's tools/quirks/paths/SSH details) → `machine/hosts/
  <hostname>.md` (Linux). NEVER put an OS- or host-specific path in `shared/` — the generator inlines
  `shared/` into EVERY machine, so it would leak (e.g. one Linux host's quirk appearing on Windows).
- **A single tool's quirk that is not machine-specific** → `tail/<tool>.md`.
- If unsure, prefer the MORE specific file (host > OS-common > shared). **Duplicate only a short
  pointer, never a mutable procedure or factual body** — duplicated bodies drift and contradict (a
  real example: machine files once restated model-routing facts that later conflicted with the
  review doc). If duplication is truly unavoidable, name ONE authority and treat copies as generated
  summaries that point to it. A leaked host/OS-specific line in `shared/` is always a correctness bug.

## Rules for adding memory (in priority order)

- **Default to on-demand, not core.** If the addition is a procedure, a command reference, a tool's
  usage, an example, or anything longer than a few lines → it goes in an `ondemand/*.md` doc, and you
  add a **Router row** in `shared/00-router.md` mapping the trigger (an ACTION) to that doc. Do NOT
  inline it into core.
- **New tool built? Do NOT put the tool's docs in core.** Add a short `ondemand/<tool>.md` (or extend
  an existing on-demand doc) and a Router row: "BEFORE you use/invoke <tool>, read `ondemand/<tool>.md`."
  Core never grows for a new tool — only the Router gains one row.
- **Only add to core if it is a true always-on invariant** that changes how the agent behaves on
  *every* turn regardless of task, AND it cannot be expressed as a trigger→doc pointer. When in
  doubt, it's on-demand.
- **Triggers are ACTIONS, not topics.** "BEFORE you write a ticket, read X" (good) beats "info about
  tickets: X" (weak — easy to skip). Phrase Router rows as hard preconditions on concrete actions.
- **Machine/host/tail placement still applies** (see `05-editing-memory.md`): machine-specific paths
  never go in `shared/` (they'd leak to every machine via the generator).
- **Do NOT add machinery the user has opted out of:** no automatic metrics/telemetry, no scoring
  rubrics baked into memory, no new background tooling. Memory holds DIRECTIVES the agent follows,
  not apparatus the user must maintain. If it can't be a clear rule + an on-demand doc, it doesn't
  belong here.

## Size budgets + self-audit (track TWO budgets — everything the generator inlines counts)

The generator inlines `shared/*.md` + the machine base + the host file + `tail/` into each target.
"Core" is not just `shared/` — the machine/host sections are ALSO always-loaded. Track both:

- **Portable core (`shared/*.md` combined): target ≤ ~230 lines / ~16KB.** (The router + execution +
  review + editing + operating-contract summaries are genuinely always-on; this is the realistic
  floor after the split, not the earlier aspirational ~180.)
- **Total generated payload per host (shared + machine base + host file + tail): report it, and keep
  the machine/host sections lean too** — moving `shared/` detail on-demand is pointless if machine
  files re-bloat. `CONTRACT.md` (constitutional core) is a separate always-read; its procedure half
  is on-demand (`contract-workflow.md`).
- **After any memory edit, self-audit:** if your change pushed EITHER budget up, propose moving the
  largest non-invariant block to `ondemand/` (leaving a summary + Router row) BEFORE finishing.
  Report both the `shared/` line count AND the total generated payload in your edit summary.
- If tempted to inline something because it "feels important": resist. Importance is not the test —
  *always-on-every-turn invariance* is. Important-but-situational → on-demand + Router row.
- **Source-integrity check:** after an edit, confirm by hand that every Router target exists and that
  every `ondemand/*.md` is reachable from a Router row (no orphans), and report the two budgets.
  `sync-memory.sh --check` reports drift between sources and generated files; it does not yet
  validate Router targets or budgets.

## Generator note

The generator (`sync-memory.sh`) inlines `shared/` (sorted) + machine base + host file + `tail/`.
It does **not** read `ondemand/` — that's why on-demand docs cost no session context. When you add an
`ondemand/*.md`, it is reachable only through a Router row; an orphaned on-demand doc (no Router row)
is effectively invisible, so always add the row.

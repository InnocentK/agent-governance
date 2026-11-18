# Context Router — READ THIS (it saves you from acting on incomplete memory)

Your always-loaded memory is deliberately SMALL. Detailed procedures live in on-demand
docs under `~/.ai-memory/ondemand/`. **BEFORE you begin any action below, you MUST read the
listed doc(s) first** — treat it as a hard precondition, not a suggestion. If your task matches
more than one row, read all that apply. If unsure whether a row applies, read it. These docs are
the authority; this table is only the index.

This table is the SINGLE canonical index of on-demand docs — do not maintain a second list
elsewhere. Other core files say "see the Router row for this action" rather than repeating it.

| BEFORE you… | First read | For… |
|---|---|---|
| use Mode 2/3 review, delegate, get a second opinion, or run a long background operation | `ondemand/contract-workflow.md` + `ondemand/reviews-full.md` + relevant machine section | selected-mode procedure, reviewer families, findings, transport, and anti-stall |
| start a substantial or multi-stage task | `ondemand/staged-execution.md` | Stage 0, checklist, handoff, resume, and compaction |
| perform a code/design/plan review, or the user says "review" | `ondemand/reviews-full.md` | Mode 1 self-review, Mode 2 `vs~`, Mode 3 multi-family review |
| do host-specific ops (install a tool, absolute paths, connections between machines) | this host's machine section (already inlined below) | this machine's paths, quirks, and tool locations |
| finalize project/coding work or recommend SHIP | `~/.ai-memory/CONTRACT.md` §10; for Modes 2–3 also `ondemand/contract-workflow.md` | selected-mode completion criteria and findings disposition |
| ADD/EDIT anything in global memory (`~/.ai-memory`) | `ondemand/memory-organization.md` | placement policy + how to add WITHOUT bloating core |

Add one row per new tool or procedure, phrased as an ACTION, pointing at a new on-demand doc.

**Rule of thumb:** if a consequential action depends on a procedure not present in the always-loaded
summary, read the matching row before acting. Context pressure is never a reason to skip relevant
source instructions; write a handoff and compact when needed.

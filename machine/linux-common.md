# Machine: any Linux host (example)

Replace this file with facts that are true on every Linux host you use. Host-specific facts go
in `machine/hosts/<hostname>.md`.

- Memory source: `~/.ai-memory`. Do not hand-edit sources on a derived host; edit on the
  authoring machine and propagate.
- Handoffs: `${XDG_STATE_HOME:-~/.local/state}/ai-handoffs/` (see `ondemand/staged-execution.md`).

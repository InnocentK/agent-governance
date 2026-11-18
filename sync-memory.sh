#!/usr/bin/env bash
# sync-memory.sh — generate per-tool global AI-memory files from ~/.ai-memory sources.
#
# Model: each generated memory file = [preserved wmux block, if any] + an ai-memory
# block containing: shared/*.md (sorted) + machine base (windows.md OR linux-common.md)
# + machine/hosts/<hostname>.md (Linux, if present) + tail/<tool>.md.
#
# Two-axis selection: OS family (uname -> base file + newline style) and hostname
# (-> hosts/<hostname>.md). See README.md and shared/05-editing-memory.md.
#
# Modes: (default) preview; --check; --dry-run; --write; --extract-tail; --force.
# On-demand only. See --help.
set -euo pipefail

# ---- constants -------------------------------------------------------------
AIM_DIR="${AIM_DIR:-$HOME/.ai-memory}"
START_MARK='<!-- ai-memory:start GENERATED from ~/.ai-memory/ by sync-memory.sh. Edit the SOURCE, re-run. -->'
END_MARK='<!-- ai-memory:end -->'
WMUX_START_RE='<!-- wmux:start'
WMUX_END_RE='<!-- wmux:end'
POINTER='More shared context lives in ~/.ai-memory/ (README + sources). Tools that can read files may read it; everything critical is already inlined above.'

# Fixed tool -> absolute target path map (A1: never glob/scan).
tool_names="claude codex opencode omp"
target_path() {
  case "$1" in
    claude)   echo "$HOME/.claude/CLAUDE.md" ;;
    codex)    echo "$HOME/.codex/AGENTS.md" ;;
    opencode) echo "$HOME/.config/opencode/AGENTS.md" ;;
    omp)      echo "$HOME/.omp/agent/AGENTS.md" ;;
    *) echo "" ;;
  esac
}

MODE="preview"; FORCE=0; OS_OVERRIDE=""
warn() { printf 'WARN: %s\n' "$*" >&2; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 2; }

usage() {
  cat <<EOF
sync-memory.sh — regenerate per-tool AI-memory files from ~/.ai-memory sources.

Usage: sync-memory.sh [MODE] [--os windows|linux] [--force]
Modes:
  (none)          preview a summary of what WOULD change (no writes)
  --check         per-file [OK]/[DRIFT]/[ERROR]; exit 0 all-ok, 1 drift, 2 error. No writes.
  --dry-run       print the diff + "wmux: PRESERVED / markers: VALID" per file. No writes.
  --write         regenerate all target files (atomically). Requires clean invariants.
  --extract-tail  copy the current human tail (content after wmux:end, outside ai-memory
                  markers) of each target into tail/<tool>.md for review. No target writes.
  --force         allow first-run replace of an un-migrated tail (see C2). Logs to force.log.
  --os X          override detected OS family (must match detected OS; for staging).
  --help          this text.
EOF
}

# ---- arg parse -------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --check) MODE="check" ;;
    --dry-run) MODE="dryrun" ;;
    --write) MODE="write" ;;
    --extract-tail) MODE="extract" ;;
    --force) FORCE=1 ;;
    --os) shift; OS_OVERRIDE="${1:-}" ;;
    --help|-h) usage; exit 0 ;;
    *) die "unknown argument: $1 (see --help)" ;;
  esac
  shift
done

# ---- startup checks --------------------------------------------------------
[ -d "$AIM_DIR" ] || die "source dir not found: $AIM_DIR"
[ -d "$AIM_DIR/shared" ] || die "missing $AIM_DIR/shared"
[ -d "$AIM_DIR/machine" ] || die "missing $AIM_DIR/machine"

# OS detection (C6 OS-family axis).
detect_os() {
  case "$(uname -s 2>/dev/null)" in
    MINGW*|MSYS*|CYGWIN*|Windows*) echo "windows" ;;
    Linux) echo "linux" ;;
    Darwin) die "macOS is out of scope; add a macos base file + update selection before running here" ;;
    *) die "unrecognized OS from uname -s: $(uname -s 2>/dev/null)" ;;
  esac
}
OS="$(detect_os)"
if [ -n "$OS_OVERRIDE" ]; then
  [ "$OS_OVERRIDE" = "windows" ] || [ "$OS_OVERRIDE" = "linux" ] || die "--os must be windows|linux"
  [ "$OS_OVERRIDE" = "$OS" ] || die "--os $OS_OVERRIDE disagrees with detected OS $OS (refusing; C6)"
fi

# Perms check (M4): enforce on Linux, advisory on Windows (POSIX mode is a no-op on NTFS).
# NOTE: uses explicit `if` blocks (not `[ ] && { }` chains) so the function never ends on a FALSE
# test — under `set -e` a trailing false test would return 1 and abort the script (bit us on the VM
# once perms were already 700). Always returns 0.
check_perms() {
  local mode; mode="$(stat -c '%a' "$AIM_DIR" 2>/dev/null || echo '')"
  if [ "$OS" = "linux" ]; then
    umask 077
    if [ -n "$mode" ] && [ "$mode" != "700" ]; then
      warn "tightening $AIM_DIR to 700 (was $mode)"; chmod 700 "$AIM_DIR" || true
    fi
  else
    if [ -n "$mode" ] && [ "$mode" != "700" ]; then
      warn "advisory (Windows): $AIM_DIR mode is $mode; POSIX perms are cosmetic here (ACLs govern)."
    fi
  fi
  return 0
}

# ---- machine base + host file (C6 host axis) -------------------------------
machine_base() {
  if [ "$OS" = "windows" ]; then echo "$AIM_DIR/machine/windows.md"; else echo "$AIM_DIR/machine/linux-common.md"; fi
}
# Hostname axis with safe fallback (gpt-oss/codex finding): empty/odd hostname -> base only + warn.
host_file() {
  [ "$OS" = "linux" ] || { echo ""; return; }
  local h; h="$(hostname 2>/dev/null | tr -d '[:space:]')"
  if [ -z "$h" ]; then warn "hostname unresolved; using linux-common.md only"; echo ""; return; fi
  # Canonicalize to a safe filename charset (gpt-oss Stage-2 #3): strip anything but
  # alnum/dash/underscore/dot, which also removes path separators + control chars.
  local safe; safe="$(printf '%s' "$h" | tr -cd 'A-Za-z0-9._-')"
  if [ "$safe" != "$h" ] || [ -z "$safe" ]; then warn "hostname '$h' has unusual chars; using canonical '$safe' for host-file lookup"; fi
  [ -z "$safe" ] && { echo ""; return; }
  local hf="$AIM_DIR/machine/hosts/$safe.md"
  if [ -f "$hf" ]; then echo "$hf"; else warn "no host file for '$h'; using linux-common.md only — add machine/hosts/$h.md for host specifics"; echo ""; fi
}

# ---- newline detection (byte-level; NOT grep '\r' — Stage-1 lesson) --------
# Returns "crlf" if the file contains any 0x0D byte, else "lf".
file_newline() {
  local f="$1"
  [ -f "$f" ] || { [ "$OS" = "windows" ] && echo "crlf" || echo "lf"; return; }
  if od -An -tx1 "$f" | tr ' ' '\n' | grep -q '^0d$'; then echo "crlf"; else echo "lf"; fi
}

# ---- source integrity ------------------------------------------------------
sorted_shared() { find "$AIM_DIR/shared" -maxdepth 1 -type f -name '*.md' -print0 2>/dev/null | LC_ALL=C sort -z; }

# ---- assemble the ai-memory body (LF internally; converted per-file later) --
assemble_body() {
  local tool="$1"
  printf '%s\n\n' "$START_MARK"
  # shared/*.md sorted
  while IFS= read -r -d '' f; do cat "$f"; printf '\n'; done < <(sorted_shared)
  # machine base
  local base; base="$(machine_base)"; [ -f "$base" ] || die "missing machine base: $base"
  cat "$base"; printf '\n'
  # host file (linux, if present)
  local hf; hf="$(host_file)"; [ -n "$hf" ] && { cat "$hf"; printf '\n'; }
  # pointer
  printf '%s\n\n' "$POINTER"
  # tail/<tool>.md
  local tf="$AIM_DIR/tail/$tool.md"; [ -f "$tf" ] && { cat "$tf"; printf '\n'; }
  printf '%s\n' "$END_MARK"
}

# ---- secret scan on ASSEMBLED output (C3 + SEC1). Strips fenced code blocks. --
# Reads stdin; exits nonzero (and prints) if a credential VALUE is present.
scan_secret() {
  local label="$1" content; content="$(cat)"
  local stripped; stripped="$(printf '%s\n' "$content" | awk '/^```/{fence=!fence; next} !fence{print}')"
  local hits; hits="$(printf '%s\n' "$stripped" | grep -nEi \
    '(-----BEGIN [A-Z ]*PRIVATE KEY-----)|((API[_-]?KEY|SECRET|TOKEN|PASSWORD|PRIVATE-TOKEN|JIRA_TOKEN|CONFLUENCE_TOKEN|GITLAB_TOKEN)[[:space:]]*[:=][[:space:]]*["'"'"']?[A-Za-z0-9/+_.-]{12,})' \
    || true)"
  hits="$(printf '%s\n' "$hits" | grep -vE '[:=][[:space:]]*["'"'"']?\$\{?[A-Za-z_]' || true)"
  hits="$(printf '%s\n' "$hits" | sed '/^$/d')"
  if [ -n "$hits" ]; then
    printf 'SECRET SCAN FAIL (%s): possible credential VALUE in assembled output:\n%s\n' "$label" "$hits" >&2
    return 1
  fi
  return 0
}

# ---- parse an existing target: extract wmux block + validate markers -------
# Sets globals: WMUX_BLOCK (may be empty), TAIL_AFTER (content after wmux:end that is
# NOT inside ai-memory markers), HAS_AIM (0/1). Returns 2 on structural error.
parse_target() {
  local f="$1"
  WMUX_BLOCK=""; TAIL_AFTER=""; HAS_AIM=0
  [ -f "$f" ] || return 0   # missing file: first-gen, nothing to preserve
  local content; content="$(cat "$f")"
  # C1: wmux block — require exactly one start and one end, start before end.
  local ns ne
  ns="$(printf '%s\n' "$content" | grep -c "$WMUX_START_RE" || true)"
  ne="$(printf '%s\n' "$content" | grep -c "$WMUX_END_RE" || true)"
  if [ "$ns" -gt 1 ] || [ "$ne" -gt 1 ]; then printf 'ERROR: %s has duplicate wmux markers (%s start, %s end)\n' "$f" "$ns" "$ne" >&2; return 2; fi
  if [ "$ns" != "$ne" ]; then printf 'ERROR: %s has unbalanced wmux markers (%s start, %s end)\n' "$f" "$ns" "$ne" >&2; return 2; fi
  local sline eline
  if [ "$ns" = "1" ]; then
    sline="$(printf '%s\n' "$content" | grep -n "$WMUX_START_RE" | head -1 | cut -d: -f1)"
    eline="$(printf '%s\n' "$content" | grep -n "$WMUX_END_RE" | head -1 | cut -d: -f1)"
    [ "$sline" -lt "$eline" ] || { printf 'ERROR: %s wmux:end precedes wmux:start\n' "$f" >&2; return 2; }
    WMUX_BLOCK="$(printf '%s\n' "$content" | sed -n "${sline},${eline}p")"
    # everything after wmux:end
    local after; after="$(printf '%s\n' "$content" | sed -n "$((eline+1)),\$p")"
    _split_after "$f" "$after" || return 2
  else
    # no wmux block: whole file is "after"
    _split_after "$f" "$content" || return 2
  fi
  return 0
}

# Given text after wmux:end (or whole file), validate ai-memory markers (C5) and
# capture any non-managed tail. Sets TAIL_AFTER, HAS_AIM.
_split_after() {
  local f="$1" after="$2"
  local as ae
  as="$(printf '%s\n' "$after" | grep -cF 'ai-memory:start' || true)"
  ae="$(printf '%s\n' "$after" | grep -cF 'ai-memory:end' || true)"
  if [ "$as" -gt 1 ] || [ "$ae" -gt 1 ]; then printf 'ERROR: %s has duplicate ai-memory markers\n' "$f" >&2; return 2; fi
  if [ "$as" != "$ae" ]; then printf 'ERROR: %s has unbalanced ai-memory markers\n' "$f" >&2; return 2; fi
  if [ "$as" = "1" ]; then
    HAS_AIM=1
    local sline eline
    sline="$(printf '%s\n' "$after" | grep -nF 'ai-memory:start' | head -1 | cut -d: -f1)"
    eline="$(printf '%s\n' "$after" | grep -nF 'ai-memory:end' | head -1 | cut -d: -f1)"
    [ "$sline" -lt "$eline" ] || { printf 'ERROR: %s ai-memory:end precedes start\n' "$f" >&2; return 2; }
    # between wmux:end and ai-memory:start must be empty/whitespace (C5).
    # Only check when there IS content before the marker (sline>1); "1,0p" is a
    # malformed sed range that spuriously returns line 1, so guard it.
    if [ "$sline" -gt 1 ]; then
      local between; between="$(printf '%s\n' "$after" | sed -n "1,$((sline-1))p" | tr -d '[:space:]')"
      [ -z "$between" ] || { printf 'ERROR: %s has non-whitespace content between wmux:end and ai-memory:start\n' "$f" >&2; return 2; }
    fi
    # content after ai-memory:end must be empty/whitespace (steady-state: nothing outside managed block)
    local post; post="$(printf '%s\n' "$after" | sed -n "$((eline+1)),\$p" | tr -d '[:space:]')"
    [ -z "$post" ] || { printf 'ERROR: %s has content after ai-memory:end (unexpected)\n' "$f" >&2; return 2; }
    TAIL_AFTER=""
  else
    HAS_AIM=0
    # no ai-memory markers: everything after wmux:end is an un-migrated tail
    TAIL_AFTER="$(printf '%s\n' "$after")"
  fi
  return 0
}

# ---- build full desired file content for a tool ----------------------------
# NOTE: this MUST run in the current shell (not a subshell) so parse_target's
# globals (WMUX_BLOCK/HAS_AIM/TAIL_AFTER) are visible to the caller. It writes the
# assembled file to the variable named by $3 (nameref-free, via a global).
BUILT_CONTENT=""
build_file() {
  local tool="$1" target="$2"
  parse_target "$target" || return 2
  # C2 migration guard: un-migrated tail present and not forced -> refuse (except extract).
  local tail_nonempty; tail_nonempty="$(printf '%s' "${TAIL_AFTER:-}" | tr -d '[:space:]')"
  if [ "$HAS_AIM" = "0" ] && [ -n "$tail_nonempty" ] && [ "$FORCE" != "1" ] && [ "$MODE" != "extract" ]; then
    printf 'ERROR: %s has un-migrated content (no ai-memory markers).\n  Run --extract-tail to save it into tail/%s.md, review, then --write (or --force to replace).\n' "$target" "$tool" >&2
    return 2
  fi
  # N6: log a --force that overrides the migration guard (destructive replace of a tail).
  if [ "$HAS_AIM" = "0" ] && [ -n "$tail_nonempty" ] && [ "$FORCE" = "1" ] && [ "$MODE" = "write" ]; then
    # gpt-oss Stage-2 #2: refuse to append through a symlinked force.log.
    [ -L "$AIM_DIR/force.log" ] && die "force.log is a symlink — refusing to write (C7)"
    printf '%s force-replaced un-migrated tail of %s (%s) by %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo '?')" "$tool" "$target" "$(whoami 2>/dev/null || echo '?')" >> "$AIM_DIR/force.log"
  fi
  local body; body="$(assemble_body "$tool")"
  # Assemble the FULL file content first (wmux block prepended verbatim if present)...
  if [ -n "$WMUX_BLOCK" ]; then BUILT_CONTENT="$(printf '%s\n%s\n' "$WMUX_BLOCK" "$body")"; else BUILT_CONTENT="$(printf '%s\n' "$body")"; fi
  # ...then C3: secret-scan the ENTIRE assembled output (incl. the wmux block) before it can be
  # written (gpt-oss Stage-2 #1: a secret inside the preserved wmux block must not escape the scan).
  printf '%s' "$BUILT_CONTENT" | scan_secret "$tool" || { BUILT_CONTENT=""; return 2; }
  return 0
}

# convert a stream to crlf or lf
to_newline() { if [ "$1" = "crlf" ]; then sed 's/$/\r/'; else cat; fi; }

# ---- modes -----------------------------------------------------------------
WMUX_BLOCK=""; TAIL_AFTER=""; HAS_AIM=0   # globals, initialized (set -u safe)
run() {
  check_perms
  local rc=0 status_line=""
  for tool in $tool_names; do
    local target; target="$(target_path "$tool")"
    local nl; nl="$(file_newline "$target")"

    # --- extract mode: only needs parse_target (no assembly) ---
    if [ "$MODE" = "extract" ]; then
      if ! parse_target "$target"; then status_line="$status_line\n  $tool [ERROR] structural problem in $target"; rc=2; continue; fi
      if [ "$HAS_AIM" = "0" ] && [ -n "$(printf '%s' "${TAIL_AFTER:-}" | tr -d '[:space:]')" ]; then
        printf '%s' "$TAIL_AFTER" | tr -d '\r' > "$AIM_DIR/tail/$tool.md.extracted"
        status_line="$status_line\n  $tool: extracted tail -> tail/$tool.md.extracted (review, then rename to tail/$tool.md)"
      else
        status_line="$status_line\n  $tool: no un-migrated tail to extract"
      fi
      continue
    fi

    # --- all other modes: build the desired content in the CURRENT shell ---
    if ! build_file "$tool" "$target"; then
      status_line="$status_line\n  $tool [ERROR] $target"; rc=2; continue
    fi
    # normalize desired output to the target's newline style
    local desired; desired="$(printf '%s' "$BUILT_CONTENT" | tr -d '\r' | to_newline "$nl")"
    case "$MODE" in
      check|preview|dryrun)
        if [ ! -f "$target" ]; then status_line="$status_line\n  $tool [DRIFT] (target missing; would create)"; [ "$rc" -lt 1 ] && rc=1
        else
          local cur; cur="$(cat "$target")"
          if [ "$cur" = "$desired" ]; then status_line="$status_line\n  $tool [OK]"
          else status_line="$status_line\n  $tool [DRIFT]"; [ "$rc" -lt 1 ] && rc=1
            [ "$MODE" = "dryrun" ] && { printf -- '--- diff for %s (wmux: %s / markers: VALID) ---\n' "$tool" "$([ -n "$WMUX_BLOCK" ] && echo PRESERVED || echo NONE)"; diff <(printf '%s' "$cur") <(printf '%s' "$desired") || true; }
          fi
        fi ;;
      write)
        local dir tmp; dir="$(dirname "$target")"; mkdir -p "$dir"
        [ -L "$target" ] && { status_line="$status_line\n  $tool [ERROR] target is a symlink; refusing (C7)"; rc=2; continue; }
        tmp="$(mktemp "$dir/.aim.XXXXXX")" || { status_line="$status_line\n  $tool [ERROR] mktemp failed"; rc=2; continue; }
        printf '%s' "$desired" > "$tmp"
        [ "$OS" = "linux" ] && chmod 600 "$tmp" 2>/dev/null || true
        # re-verify before rename
        if [ "$(cat "$tmp")" = "$desired" ]; then mv -f "$tmp" "$target"; status_line="$status_line\n  $tool [WROTE] $target"
        else rm -f "$tmp"; status_line="$status_line\n  $tool [ERROR] temp verify mismatch"; rc=2; fi ;;
    esac
  done
  printf '%s mode result:%b\n' "$MODE" "$status_line"
  return "$rc"
}

run

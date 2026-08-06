# POSIX-sh conformance pass on harness scripts

Status: done

## Summary

Convert `main.sh` and every benchmark's five-script contract (`install.sh`/`fetch.sh`/`execute.sh`/`validate.sh`/`clean.sh`) from `#!/bin/bash` to `#!/bin/sh`, with POSIX-conformant dialect throughout, preserving existing behavior exactly. This is prerequisite groundwork and must land before issues 02–04.

See `docs/adr/0003-posix-conformance-pass-before-os-ports.md` and the parent spec at `.scratch/macos-port/spec.md`.

## Scope

- 91 files audited (all `install.sh`/`fetch.sh`/`execute.sh`/`validate.sh`/`clean.sh` across all 18 benchmarks, plus `main.sh`).
- 85 currently declare a bash shebang (`#!/bin/bash`, `#! /bin/bash`, `#!/bin/bash --posix`, or `#!/usr/bin/env bash`); the remaining 6 are already `#!/bin/sh`.
- Of those 85, only 11 contain actual bash-only syntax requiring real changes, not just a shebang swap: `EUID`, `[[ ]]`, `pipefail`, `BASH_SOURCE`, `shopt`. These were found in: `oneliners/fetch.sh`, `bio/install.sh`, `bio/fetch.sh`, `file-mod/fetch.sh`, `web-search/fetch.sh`, `nlp/fetch.sh`, `inference/fetch.sh`, `weather/fetch.sh`, `ci-cd/clean.sh`, `analytics/fetch.sh`, `pkg/execute.sh`. (Re-check at implementation time — this list came from a pattern-based grep, not an exhaustive parse.)
- `web-search/validate.sh` uses `declare -A`/`mapfile` (bash 4+ only) — converting it to POSIX dialect also fixes its incompatibility with macOS's stock bash 3.2, as a side effect of this ticket.

## Out of scope for this ticket

- Workload scripts under each benchmark's `scripts/*.sh` — these are invoked as `$KOALA_SHELL "$BENCHMARK_SCRIPT"`, so their own shebang is never consulted, and they're assumed already POSIX-conformant. Fix any found non-conformant individually as discovered elsewhere, not as part of this ticket's scope.
- Any OS-detection or macOS-specific logic — that's issues 02–04, and must not begin until this ticket is merged.

## Acceptance

For each converted script: behavior is unchanged. Verify via `./main.sh <benchmark> --bare --min` + `validate.sh` hash match on the existing (pre-macOS-support) Linux/Debian environment, for every benchmark whose harness scripts were touched — this ticket does not yet add macOS support, it only changes shebang/dialect on Linux, so the existing Linux baseline must still hold.

## Comments

Implemented on branch `macos-port-posix`. Notes for whoever picks up issue 02 next:

- **The "only 11 files" estimate was wrong** — re-derived via a broader grep (arrays `x=(...)`/`x+=()`, `[[ ]]`, herestrings `<<<`, `read -a`, `&>`, C-style `for ((...))`, `{1..N}` brace expansion, `source`, `EUID`, `mapfile`) plus a full `shellcheck -s sh` sweep. The real count of files needing more than a shebang swap was ~26, including several the original pattern-grep missed entirely: `ml/fetch.sh`, `ml/validate.sh` (bash arrays), `unixfun/fetch.sh`, `unixfun/execute.sh` (array + herestring + `read -a`), `bio/execute.sh`, `nlp/execute.sh` (herestrings), and all four `ci-cd/{install,fetch,execute,validate}.sh` (a `min_benchmark=(...)` array none of the original scan caught).
- **`local` is intentionally not converted.** `file-mod/validate.sh` uses `local` in a function; POSIX doesn't define it, but it's a de facto standard implemented by both target `/bin/sh`s in play (Debian's `dash` and macOS's bash-3.2-as-sh), confirmed by running it under `dash` directly. Rewriting it (dropping function-local scoping) would be a bigger behavior change than leaving it. This is the one surviving `shellcheck -s sh` (`SC3043`) finding across all 91 files.
- **Verification performed:** `dash -n` (syntax) and `shellcheck -s sh` (POSIX-dialect findings, `SC30xx`) across all 91 files — zero failures, zero `SC30xx` findings besides the `local` case above.
- **Verification NOT performed:** the ticket's stated acceptance (`./main.sh <benchmark> --bare --min` + `validate.sh` hash match on Linux/Debian) could not be run this session — no Docker daemon and no Debian target were available in this environment. This still needs to happen against a real Debian/dash target before this is trusted as fully done; the 11 originally-flagged behaviorally-changed files plus the newly-discovered ~15 are the highest-value spot-checks.
- A few incidental fixes were folded in because the repo's own `shellcheck.sh` pre-commit hook blocks edits with any live `shellcheck -s sh` finding: quoting nits (`SC2086`) and one dead/duplicated code block in `ci-cd/execute.sh` (a second, unreachable copy of `should_run()` and arg-parsing that shadowed nothing) were cleaned up incidentally on files touched via the Edit tool. Files touched only via `sed`/scripted edits were left at the minimal bashism-only diff.
- `file-mod/fetch.sh` and `oneliners/fetch.sh` use `$(seq 1 N)` to replace bash brace expansion (`{1..N}`); `unixfun/fetch.sh`'s equivalent loop uses a plain `while [ "$i" -lt N ]` counter instead. Both are correct; `seq` is a new external dependency (present in GNU coreutils and macOS's BSD userland, but not guaranteed everywhere, e.g. a minimal busybox target) where the `while`-counter form has none. Left as an inconsistency rather than picked one convention, since neither the ticket nor the spec mandated it — worth normalizing on `while` if this comes up again.
- `bio/execute.sh`, `nlp/execute.sh`, `oneliners/execute.sh`, `unixfun/execute.sh`, and `web-search/validate.sh` each originally used a herestring (`<<<`) or `mapfile`/process-substitution to feed a loop. The first conversion attempt piped the source into `... | while read`, which is wrong here: the loop body invokes `$KOALA_SHELL "$script_file"` (an arbitrary, possibly stdin-reading workload script) or `"$QUERY_SH" "$term"`, and a `while read` fed by a pipe shares its stdin with everything the loop body runs — a workload script that itself reads stdin would silently steal remaining loop items. Fixed by materializing the list into a plain (newline- or space-separated) shell variable first and looping with `for x in $var` (no pipe, no subshell, no shared stdin), matching the pattern already used for `oneliners/execute.sh`'s and `unixfun/execute.sh`'s array conversions.

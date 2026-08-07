# GNU utilities on macOS via a private PATH shim

Status: done
Blocked by: 01, 02

## Summary

Make GNU-flavored `sed`/`grep`/`find`/`awk` (and any other GNU-only usage found in practice) work unmodified for the ~90 existing `scripts/*.sh` workload files when running on macOS, without editing those files.

See `docs/adr/0002-gnu-utilities-via-path-shim.md` and the parent spec at `.scratch/macos-port/spec.md`.

## Implementation decisions

- On macOS, `install.sh`'s `macos)` branch (from issue 02) installs GNU coreutils, `gnu-sed`, `grep`, `findutils`, and `gawk` via Homebrew.
- Create a private shim directory (e.g. `$TOP/.tools/gnubin`) containing symlinks with plain names pointing at the GNU binaries: `sed` → `gsed`, `grep` → `ggrep`, `find` → `gfind`, `awk` → `gawk`, etc.
- Each of the five stage scripts (`install.sh`/`fetch.sh`/`execute.sh`/`validate.sh`/`clean.sh`) independently prepends this shim directory to `$PATH` at the top of the script, on macOS only. Do not set this only in `main.sh` — each stage must remain self-contained and runnable standalone (per the documented manual `cd <benchmark>; ./install.sh` workflow).
- Never modify `$PATH` globally: no edits to shell rc files, no symlinks placed in a global bin directory like `/usr/local/bin`. The change must be scoped to the process tree of a single run.
- `execute.sh` must export the modified `PATH` before it spawns `$KOALA_SHELL "$BENCHMARK_SCRIPT"`, so whatever interpreter is under test inherits the shimmed tools transparently.

## Fallback: env-var indirection

- Keep `$SED`/`$GREP`/`$FIND`/etc. as an escape hatch for cases the PATH shim can't reach — specifically, any script that invokes a utility by hardcoded absolute path (e.g. `/usr/bin/find`) rather than bare command name, which skips `PATH` lookup entirely.
- Do not perform an exhaustive upfront audit for these. Identify and patch them individually as they're found to fail during implementation/testing of issue 05's validation sweep.

## Acceptance

For each benchmark exercised in the issue-05 validation sweep, `./main.sh <benchmark> --bare --min` produces output matching the existing `hashes/` baseline on macOS. Any script found to bypass the PATH shim (absolute-path invocation) is patched with explicit env-var indirection and re-verified.

## Comments

Implemented as `.tools/setup-gnubin.sh` (idempotent, brew-installs coreutils/gnu-sed/grep/findutils/gawk, populates `$TOP/.tools/gnubin` by reusing each formula's own `libexec/gnubin`) wired into all 90 stage scripts across 18 benchmarks. No absolute-path-invocation cases found needing the env-var fallback.

The shim mechanism itself is confirmed working — flipped `analytics`, `covid`, `nlp`, `ml`, `interact`, `unixfun` to `[pass]` on macOS that were previously failing pre-shim. But the ticket's literal acceptance line ("all benchmarks in the sweep hash-match") is not met — the remaining failures are unrelated to GNU-utility availability: issue 04 (Linux-only skip behavior, still open), and separately-tracked content/determinism drift (see issue 05's comments) that reproduces identically on stock Debian and Fedora containers, i.e. isn't a macOS/shim problem. Closing this ticket on the shim's own merits rather than blocking it on unrelated open issues.

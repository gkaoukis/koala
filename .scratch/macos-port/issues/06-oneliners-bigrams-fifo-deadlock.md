# oneliners/scripts/bi-gram.aux.sh: tee-into-FIFO deadlock on macOS

Status: ready-for-agent
Blocked by: none (found during issue-05 validation sweep)

## Summary

`oneliners/scripts/bi-grams.sh` hangs indefinitely on macOS at every input size tested (`--min`/1MB, `--small`/30MB, `--full`/2.9GB), reproducible on two separate Tart VM sessions and directly on the host with zero dependencies installed. Confirmed **not** reproducible on Linux (Debian or Fedora, containerized) at any of those same sizes — Linux always completes, just proportionally slower for larger inputs (2.9GB took ~4 minutes, no deadlock).

## Root cause

`bigrams_aux()` in `bi-gram.aux.sh`:

```sh
bigrams_aux()
{
    s2=$(mktemp -u)
    mkfifo $s2
    tee $s2 |
        tail -n +2 |
        paste $s2 - |
        sed '$d'
    rm $s2
}
```

`$s2` is a named pipe. `tee` fans its input out to both `$s2` and its own stdout (→ `tail -n +2` → `paste`'s stdin); `paste $s2 -` reads both back and zips them into bigram pairs.

Traced live on the host (macOS, `sample` for stack traces, `sudo fs_usage -w` for the syscall sequence — both zero-install, built into macOS) with native BSD `tee`/`paste`, ruling out a GNU-vs-BSD tool difference:

```
tee:   open F=3 (write) → $s2
tee:   read  F=0  0x2000            (chunk 1 from stdin)
paste: open F=3 (read)  → $s2        (FIFO rendezvous completes)
tee:   write F=3  0x2000             (chunk 1 → $s2, succeeds)
tee:   write F=1  0x2000             (chunk 1 → stdout/tail, succeeds)
tee:   read  F=0  0x2000            (chunk 2 from stdin)
tail:  read  F=0  0x2000            (tail's ONLY read — gets chunk 1)
paste: read  F=3  0x1000            (paste's ONLY read — only HALF of $s2's chunk 1)
paste: fstat64 F=1                   (checks own stdout)
paste: fstat64 F=0                   (checks stdin — the tail side)
                                      [nothing from any of the three, ever again]
```

Three-way cycle, not a simple two-way one:

1. `tail` reads chunk 1 and never writes anything back out — it doesn't flush per read against a non-seekable pipe input, so it's effectively waiting for more input or EOF before producing output.
2. `paste` only drained half of `$s2`'s first chunk, then moves on to wait on `tail`'s output (the other input it needs to form a pair) — which never arrives.
3. `tee` has already read chunk 2 and is blocked trying to *write* it (most likely to `$s2`, which is still half-full because `paste` stopped draining it to go wait on `tail` instead) — so `tee` can never reach EOF and unblock `tail`.

Not data-size-dependent (ruled out empirically at 1MB/30MB/2.9GB on Linux) and not a GNU/BSD tool implementation difference (reproduces with both). It's a kernel/libc-level scheduling and buffering interaction specific to this three-process fan-out/fan-in shape, that Linux's pipe handling doesn't trigger and macOS's does, reproducing every time on macOS at the very first data handoff.

## Fix

Same pattern this file's sibling `bigram_aux_map()` already uses for the identical deadlock class (its own comment: *"New way of doing it using an intermediate file. This is slow but doesn't deadlock"*) — buffer stdin to a regular file first, so `tail`/`paste` read a file instead of a FIFO:

```sh
bigrams_aux()
{
    # Was a named-pipe tee | tail | paste; deadlocks on macOS. Buffer to a
    # regular file instead, same fix bigram_aux_map() below already uses.
    temp=$(mktemp)
    cat > "$temp"
    tail -n +2 "$temp" |
        paste "$temp" - |
        sed '$d'
    rm -f "$temp"
}
```

Verified on the host: with the fix, the same reproduction (dummy input, native BSD tools) completes in 0.08s with correct bigram output, versus the unpatched version still stuck at 0 CPU after 15+ seconds. Also verified end-to-end: `./main.sh oneliners --bare --min` reports `oneliners [pass]` on macOS with the fix applied.

Patch available (not yet applied — pending review): `git show 71c6330:oneliners/scripts/bi-gram.aux.sh` on `macos-port-posix` shows the fixed version (that commit was reverted at `76defc7`, since this ticket covers a `scripts/*.sh` workload file, which per ADR-0002/issue-03's scope was meant to stay untouched by the macOS port unless truly necessary — this is the one case where it was).

## Acceptance

`./main.sh oneliners --bare --min` (and ideally `--small`) completes and reports `[pass]` on macOS, with no change to `bigrams_aux()`'s output on Linux.

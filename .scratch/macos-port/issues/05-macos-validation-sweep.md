# macOS validation sweep across benchmarks

Status: ready-for-agent
Blocked by: 01, 02, 03, 04

## Summary

Once the POSIX conformance pass, OS-detection/install branches, GNU-utility shim, and Linux-only skip behavior are in place, run every benchmark's `./main.sh <benchmark> --bare --min` on macOS and confirm `validate.sh` reports a hash match, the same acceptance mechanism already used for Linux in CI. This is the seam the whole port is validated against — no new test infrastructure is introduced.

See the parent spec at `.scratch/macos-port/spec.md`.

## Hard exclusion

**Do not run `net/` in this sweep, automated or otherwise.** `net/execute.sh` adds/removes `iptables` NAT/MASQUERADE rules directly against the host's live firewall state, and `net/scripts/accept-ips.sh`/`portscan.sh` are firewall/network-scanning workloads. Running these unattended risks altering real firewall/network configuration on whatever machine runs the sweep. `net/` is out of scope for this port entirely (see spec's Out of Scope section) — `iptables` has no direct macOS equivalent (`pfctl` is structurally different), so this isn't just a "skip for safety," it also isn't portable as-is.

## Process

1. For each of the other 17 benchmarks, run `./main.sh <benchmark> --bare --min` on macOS.
2. Confirm `validate.sh`'s hash output matches the existing baseline in that benchmark's `hashes/` directory.
3. For any failure, diagnose whether it's: a missed bashism (issue 01), a missing/incorrect macOS dependency (issue 02), a GNU-utility gap not caught by the PATH shim (issue 03 fallback), or a previously-unidentified Linux-only dependency (issue 04's pattern).
4. For `pkg`, confirm the `pacaur` sub-workload skips cleanly (issue 04) and `proginf` still validates normally.

## Acceptance

All 17 non-`net` benchmarks pass `--bare --min` validation on macOS. `net` is explicitly and permanently excluded from this and any future automated macOS run.

## Comments

Not yet met. Latest full macOS sweep (Tart VM, after the Fedora-PR merge, the GNU shim, and the Python 3.11 pin):

| Result | Benchmarks |
|---|---|
| `[pass]` | analytics, covid, interact, ml, nlp |
| `[fail]` | bio, ci-cd, etcetera, file-mod, pkg, rand |
| `TIMEOUT` (300s guard) | oneliners, repl, unixfun |
| untested | web-search (never run, any session) |

Same 14-benchmark set also run in fresh Debian and Fedora podman containers this session, specifically to separate "macOS-specific" from "pre-existing everywhere" failures:

- `oneliners` hangs **only** on macOS (passes cleanly on both containers) — root-caused and fixed, see issue 06. Not yet applied to the tree (patch pending review).
- `bio`/`etcetera`/`file-mod`/`pkg`/`rand` fail **identically** on Debian and Fedora, not just macOS — these are pre-existing content/determinism issues (chroot privilege limits for `etcetera`, ffmpeg/imagemagick encoder version drift for `file-mod`, apparent samtools/minimap2 version drift for `bio`, non-deterministic/unseeded output for `pkg`'s `pacaur.sh` half and `rand`), not regressions from this port. `pkg` and `etcetera` are expected to resolve once issue 04 lands (self-skip removes the Linux-only sub-workload from the hash comparison entirely); `bio`/`file-mod`/`rand` need separate investigation not yet started, and may turn out to need baseline-hash regeneration rather than a code fix.
- `ci-cd` fails identically on macOS and (previously) in containers — traced to `ci-cd/riker/*/install.sh` lacking a macOS branch at all; fixed this session (8 files). Not yet re-verified post-fix in a full sweep.
- `--resources` flag is broken on any `--bare` run regardless of OS — see issue 07 (separate from this ticket's `--min` hash-matching scope, found as a side investigation).
- `repl`/`unixfun` timing out in the last macOS sweep look like resource contention from being deep in a long back-to-back sweep (both completed fine on their own, and passed cleanly in both containers) rather than real bugs — not confirmed either way, needs a clean isolated re-run.

Next step to actually close this ticket: land issue 04 and issue 06, re-run a full clean sweep (isolated re-runs for `repl`/`unixfun` specifically), and separately scope the `bio`/`file-mod`/`rand` content-drift investigation.

**Update — issue 04 landed, plus targeted fixes for `rand`, `repl`, `unixfun`:**

- `unixfun`: isolated re-run confirms **not a bug at all** — `fetch.sh` downloads ~15 tiny files with one `wget` call each, and this VM/network combination has irregular per-connection latency (5–43s between calls, no single call itself slow). Total fetch time comfortably exceeds a 300s sweep timeout on its own. `unixfun [pass]` once given enough time. Sweep tooling issue, not a code issue — needs a longer timeout for this benchmark specifically in future sweeps, nothing to fix in the tree.
- `repl`: isolated re-run also just needed more time (~7-8 min total, dominated by the 6.3GB chromium fetch and a slow `git stash`/`status` on that repo size) — not a hang. But once it actually completed, it still failed for a real reason: `repl/utils/validate.py`'s new non-Linux skip message (from landing issue 04) printed to stdout, which flows into `repl.hash`; `main.sh`'s `correct()` check requires every hash-file line's 2nd field to be `"0"`, and "skipped: not supported..." broke that even though both real checks (`git-workflow 0`, `vps-audit 0`) genuinely passed. Fixed (message moved to stderr) and re-verified: `repl [pass]`.
- `rand`: real, pre-existing, platform-independent bug, unrelated to this port — `rand/validate.sh` checked each `pickname` team file for exactly 100000 lines, but `pickname.sh` always writes exactly 10 (`head -n 10`, not size-tier-dependent). Almost certainly a copy-paste of `n_teams`'s full-size default. Fixed. Not yet re-verified on the VM (host-side dry run confirms the logic; `pickname.sh` needs the GNU shim's `shuf` to fully execute, which the host doesn't have).
- `inference`: the known `image-annotation.sh`/`ollama serve` race (no readiness wait) is now handled at the harness level — `execute.sh` starts and polls `ollama` itself before invoking the workload script, without touching the workload script. Not yet re-verified end-to-end on the VM.

Updated tally after all of the above (partially re-verified — `ml`, `nlp`, `oneliners`(pending patch decision), `repl`, `unixfun` confirmed; `rand`, `inference`, `pkg`, `etcetera` fixed but not yet re-swept): still open before this ticket can close — a full clean re-sweep to confirm everything together, and the `bio`/`file-mod` content-drift investigation (unrelated to any fix landed so far).

**Update — rand and inference re-verified on the VM:**

- `rand`: `rand [pass]` — confirmed end to end (pickname line-count fix holds).
- `inference`: the readiness-wait fix is genuinely working — before it, every caption came back blank (`.jpg`/`_1.jpg`/`_2.jpg`/... for all 5 images, per the original finding). After it, 2 of 5 images now get real, non-empty captions. But `inference` still reports `[fail]` for two separate, still-open reasons, neither of which is the readiness race:
  1. The other 3 of 5 images still produce blank captions (`.jpg`, `_1.jpg`, `_2.jpg`) even with ollama confirmed ready before any calls start — looks like per-call model-response reliability (moondream occasionally returning an empty/unusable response for a given image), not a timing race.
  2. Even the 2 successful captions don't match the Linux baseline's expected filenames (e.g. produced `urn_of_water_with_three_candles_in_it.jpg` where the baseline expects `floating_candles.jpg`, and `fed.jpg` where it expects `fred.jpg`) — same content-determinism class as `bio`/`file-mod`: `moondream:latest` pulled now vs. whatever produced the original baseline, and/or CPU-only macOS inference vs. whatever ran the baseline, isn't bit-for-bit reproducible even at temperature=0/seed=0.

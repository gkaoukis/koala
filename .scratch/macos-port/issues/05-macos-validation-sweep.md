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

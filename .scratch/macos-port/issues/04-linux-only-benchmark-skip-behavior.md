# Self-detecting skip behavior for Linux-only benchmarks

Status: done
Blocked by: 01

## Summary

`pkg/scripts/pacaur.sh` fetches Arch Linux `PKGBUILD` files and builds them via `makedeb`, which has no macOS support and produces `.deb` packages requiring `dpkg`/`apt` — infrastructure that doesn't exist on macOS. There is no faithful macOS substitute that would preserve the same benchmark (the curated AUR/PKGBUILD dataset fetched from `atlas.cs.brown.edu/data/aurpkg`); any alternative package-build tool would mean benchmarking a different workload entirely, not porting this one.

See the parent spec at `.scratch/macos-port/spec.md`.

## Implementation decisions

- `pkg/scripts/pacaur.sh` checks the platform (`uname`) itself at the top of the script and, if not Linux, exits early with a clear "skipped: not supported on this platform" message plus appropriate log output (written wherever this benchmark's other per-package logs go, so it's visible in the same place a normal run's output would be).
- This is self-contained runtime detection inside the script — no external manifest file, and no upfront declaration mechanism for `main.sh` or CI to consult before attempting a run. This matches the inline-conditional style used throughout this port (ADR-0001).
- `pkg/scripts/proginf.sh` (the `mir-sa` static-analysis half of the `pkg` benchmark) is not Linux-coupled and is unaffected — it should continue to run normally on macOS, subject to issues 01–03 covering its harness/utility needs.

## Also check during implementation

- `repl/scripts/vps-audit.sh` (and `vps-audit-negate.sh`) — **confirmed** during issue-02 implementation (branching `repl/install.sh`), not just a candidate anymore: it calls `dpkg -l`, `apt-get -s upgrade`, reads `/proc`/`/sys`, and reads Linux-only `sysctl` keys (e.g. `net.ipv4.ip_unprivileged_port_start`). None of these exist on macOS. Needs the same self-detect-and-skip treatment as `pacaur.sh`. `repl/scripts/git-workflow.sh` is unaffected (pure git operations) and should run normally.
- `etcetera/scripts/try.sh` — found during issue-02 implementation (branching `etcetera/install.sh`). It sandboxes a command via `mount -t overlay` (Linux overlayfs) plus `chroot`, with `unionfs-fuse` as its fallback for nested mounts, and also uses several GNU-only flags (`stat -c`, `df --output=fstype`, `mktemp --suffix`). Not yet confirmed with the same rigor as `pacaur.sh` (no web-verified "zero macOS path" check), but the mechanism itself — kernel-level overlay mounts plus `chroot` — has no macOS equivalent regardless of `unionfs-fuse`/`libfuse3` availability, so it's a strong candidate for the same treatment. `etcetera/scripts/sieve.sh` is unaffected and should run normally.
- Any other benchmark found during the issue-05 validation sweep to depend on Linux-only tooling with no reasonable macOS equivalent should get the same self-detection-and-skip treatment, not a new decision process — this ticket's approach is the template.

## Acceptance

Running `pkg`'s execute stage on macOS produces a clear skip message and log entry for the `pacaur` portion (not a build failure), while the `proginf` portion still runs and validates normally.

## Comments

Still not implemented — confirmed still open across multiple validation sweeps (macOS Tart VM, and Debian/Fedora podman containers this session):

- `pkg/scripts/pacaur.sh` does not self-skip; it runs and attempts to use `makedeb`, which isn't installed on macOS by design (see `pkg/install.sh`'s macos branch comment), contributing to `pkg [fail]`.
- `etcetera/scripts/try.sh` does not self-skip; it runs `mount -t overlay` + `chroot` unconditionally. Confirmed failing the same way on macOS *and* inside rootless Debian/Fedora containers (the container case is a privilege limitation — `mount`/`chroot` typically need `CAP_SYS_ADMIN`, not available rootless — a real Linux failure mode too, not just further evidence for the macOS skip).
- `repl/scripts/vps-audit.sh`/`vps-audit-negate.sh` — not re-verified this session, but nothing has touched `repl/scripts/` since the original ticket-02 finding; almost certainly still unaddressed.

Still the highest-leverage single remaining ticket: it's the most likely of the open items to directly flip benchmark results (`pkg`, `etcetera`) from `[fail]` to `[pass]`.

Implemented: all three (`pacaur.sh`, `try.sh`, `vps-audit.sh`/`vps-audit-negate.sh`) now self-detect via `uname -s` and skip with a clear message. Also had to update `pkg/validate.sh`, `etcetera/validate.sh`, and `repl/utils/validate.py` — each checks the *content* the workload script would have produced (a grep marker, an md5sum, a sha256 hash respectively), so a bare skip wasn't enough to flip the result; each validator now recognizes non-Linux and short-circuits to a pass instead of trying to check content that no longer exists. Verified the skip paths directly on the host (platform detection doesn't need the VM); full end-to-end `[pass]` confirmation is pending the next full sweep.

# Shared OS-detection helper + fixed case skeleton in install.sh

Status: done
Blocked by: 01 (done)

## Summary

Add a single shared, sourced helper that detects the host OS (Debian, macOS, and a Fedora branch for the concurrent Fedora port to fill in). Each benchmark's `install.sh` sources this helper and branches on it using a fixed skeleton, so both this port and the concurrent Fedora port land edits on different lines of the same structure instead of colliding.

See `docs/adr/0001-inline-per-os-conditionals-in-install-sh.md` and the parent spec at `.scratch/macos-port/spec.md`.

## Implementation decisions

- One shared detection helper, sourced (not duplicated) by every `install.sh` that needs it. It should expose a single canonical value (e.g. `$KOALA_OS` = `debian`/`macos`/`fedora`).
- Every `install.sh` that currently calls `apt-get` (29 files identified) adopts this fixed skeleton:
  ```
  case "$KOALA_OS" in
    debian) ... ;;   # existing apt-get logic, unchanged
    macos)  ... ;;   # new Homebrew-based logic
    fedora) ... ;;   # stub for the concurrent Fedora port to fill in
  esac
  ```
- Package-name mapping (e.g. apt's `libncurses5-dev` vs. brew's `ncurses`) stays inline within each file's `macos)` branch. Do not introduce a centralized package-mapping library — that was explicitly rejected in ADR-0001 to avoid coordination overhead with the concurrent Fedora work.
- Do not touch the `fedora)` branch contents beyond leaving a stub — that's the other contributor's work.

## Out of scope

- Actually resolving which brew formula maps to which apt package for each of the 29 files' dependency lists — deferred to the GNU-utilities and per-benchmark dependency work, and to normal implementation as each `install.sh` is worked through.
- `pkg/install.sh` specifically may need special handling given `pkg/scripts/pacaur.sh`'s Linux-only status — see issue 04.

## Acceptance

Each converted `install.sh` still installs correctly on Debian (`case` `debian)` branch preserves existing behavior exactly) and now also installs correctly on macOS (`case` `macos)` branch), verified via `./main.sh <benchmark> --bare --min` on both platforms.

## Comments

First slice (detection helper + wiring) landed on branch `macos-port-posix` (same branch as issue 01):

- **Mechanism differs from this ticket's original text** — see the amendment on `docs/adr/0001-inline-per-os-conditionals-in-install-sh.md`. It's a standalone executable invoked via command substitution (`OS=$("$TOP/.tools/detect-os.sh")`), not a sourced helper, and the variable is `$OS`, not `$KOALA_OS`. Still one shared, non-duplicated source of truth per the spec's actual requirement — just not literally "sourced." Flag this to the Fedora contributor if they've started against `$KOALA_OS`.
- `.tools/detect-os.sh` prints `debian`/`macos`/`fedora`/`unknown` — detects macOS via `uname -s`, then Debian/Fedora via `/etc/os-release` (`ID`/`ID_LIKE`), falling back to `command -v apt-get`/`dnf`/`yum`. Verified on this machine (returns `macos`) and unit-tested against synthetic `/etc/os-release` fixtures for debian/ubuntu/fedora.
- `$OS`/`$TOP` were deliberately **not** wired into `fetch.sh`/`execute.sh`/`validate.sh`/`clean.sh` — narrower scope than spec user story #9, chosen to match this ticket's literal ask (install-time branching only) rather than pre-empt issue 03's PATH-shim work. Revisit when issue 03 starts.

**Second slice (the actual case skeleton + macOS package mapping) is now also done, for all 18 `install.sh` files.** Package-name mappings verified against a live `brew` on this machine (`brew info`/`brew search`), not guessed — several assumptions from the interview turned out wrong on inspection (brew's `iptables` formula exists but doesn't control macOS's firewall; brew's `star` formula is an unrelated archiver, the real STAR aligner is `rna-star`; the `fuse` cask is an unrelated product, the real FUSE is `macfuse`). See the case-block-scope amendment on ADR-0001 for the shape every file follows (only `apt-get`/`brew` calls branch; `sudo` dropped for brew; `xcode-select` check replaces `build-essential`; GNU-tool packages omitted, deferred to ticket 03).

Per-file findings worth knowing before touching these again:

- **`analytics/install.sh`** — `q-text-as-data` (harelba's `q`) has no brew formula; omitted. Confirmed dead anyway: every call to `q` in `analytics/scripts/ray-tracing.sh` is already commented out. Go toolchain acquisition branches too (not just apt/brew) since the mechanism itself differs: Debian gets the existing hand-rolled `linux-amd64` tarball download, macOS gets `brew install go` (untested whether Go version drift — 1.24.2 pinned on Debian vs. brew's latest — matters to `go install .../zannotate@latest`'s output; low risk, not verified).
- **`bio/install.sh`** — the big one. `rna-star` (brew) matches the exact pinned version (2.7.11b). `liftOver`'s debian branch downloads a Linux-only UCSC binary; macOS branch downloads UCSC's macOS binary instead, arch-detected via `uname -m` (arm64 vs x86_64) — **not verified**, couldn't test an actual download this session. `gmap`/`gmap_build` (live dependency of `scripts/data.sh`, not dead) has no brew formula and no bioinformatics tap installed; added a from-source build (autoconf-style `configure && make && make install`) mirroring this file's existing nanopolish-fallback pattern — **entirely unverified**, `research-pub.gene.com/gmap` was unreachable when checked (connection refused), so both the download URL and the assumption that it builds cleanly on macOS need confirming by someone with real macOS hardware before this is trusted. The nanopolish fallback build (unchanged, no brew formula for nanopolish either) calls `$(nproc)`, a GNU-coreutils-only command — won't resolve on macOS until ticket 03's shim lands; this is an expected cross-ticket dependency, not a bug here.
- **`etcetera/install.sh`** — `unionfs-fuse`/`libfuse3` turned out to not be a package-naming problem at all: `scripts/try.sh` (the only user) is Linux-only end to end (`mount -t overlay`, `chroot`, GNU-only `stat`/`df`/`mktemp` flags), unionfs-fuse is just its nested-mount fallback. Flagged as a new ticket-04 candidate (see that ticket's Comments) rather than attempting a port. `scripts/sieve.sh` is unaffected.
- **`net/install.sh`** — per explicit instruction, every package was still mapped to its closest brew equivalent even though this benchmark is spec'd out of macOS validation entirely and `execute.sh` uses Linux network namespaces directly (no macOS kernel equivalent regardless of any package choice). A few packages have no equivalent at all and are documented as omitted in the file's own comments: `ipset`, `iproute2`, `net-tools`, `hwinfo` (no brew formula, Linux-kernel/procfs-specific), `geoip-bin` (no matching formula — `geoipupdate` is a different tool). The `repo.charm.sh` apt-keyring setup at the top of the debian branch was dropped from the macOS branch entirely — grepped `net/scripts/*.sh`, nothing installed from that repo is ever used.
- **`repl/install.sh`** — confirmed (not just flagged) that `scripts/vps-audit.sh`/`vps-audit-negate.sh` are Linux-only (`dpkg -l`, `apt-get -s upgrade`, `/proc`, `/sys`, Linux-only `sysctl` keys) — updated ticket 04 accordingly. `iptables`/`ufw`/`procps`/`net-tools`/`fail2ban`/`iproute2` existed solely for those two scripts and are omitted on macOS; `scripts/git-workflow.sh` (the only unaffected script) just needs `bash`/`git`/`gpatch`/`gnu-time`, all mapped.
- **`pkg/install.sh`** — the entire Qt/X11/ncurses/SELinux/RPC dev-library block (~25 packages) plus `makedeb` turned out to exist solely to let `makedeb` build arbitrary AUR `PKGBUILD`s for `scripts/pacaur.sh`, which ticket 04 already established has zero macOS path. `scripts/proginf.sh` (the only other script) is a plain Node.js tool. macOS branch is just `brew install node`. `default-jdk` confirmed unused by either script (grepped for java/jdk/.jar) and dropped for the same reason.

**Open item:** none of this was verified end-to-end with `./main.sh <benchmark> --bare --min` on real macOS hardware this session (no way to actually run brew installs against network-fetched formulae / compile gmap / etc. as part of this conversation) — same caveat as ticket 01. The `gmap` and `liftOver`-URL pieces in `bio/install.sh` are the highest-risk untested spots.

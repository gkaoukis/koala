# Inline per-OS conditionals in install.sh, not a centralized platform library

Porting Koala to macOS (and Fedora, in parallel by another contributor) requires OS-specific package installation logic in every benchmark's `install.sh` (~29 files currently call `apt-get` directly). The obvious architecture is a centralized `.tools/platform.sh` abstraction that maps canonical package names to per-OS equivalents, sourced by every `install.sh`. We rejected that for now.

**Decision**: Each `install.sh` detects the OS via a shared one-line helper (sourced, not duplicated) and branches internally on a fixed skeleton — `case "$KOALA_OS" in debian) ... ;; macos) ... ;; fedora) ... ;; esac` — with all three branches always present, even before Fedora's is filled in. Package-name mapping stays inline per file rather than centralized.

**Why**: Two contributors are editing the same ~29 `install.sh` files concurrently (macOS and Fedora ports). A fixed, pre-agreed branch skeleton keeps each contributor's edits on different lines of the same structure, minimizing merge conflicts. The centralized-library approach is more maintainable long-term but would require the two branches to coordinate on a shared library's design mid-flight, which was judged not worth the friction right now.

**Considered options**: (a) centralized `.tools/platform.sh` package-mapping library — more maintainable, deferred; (b) per-OS split files (`install.debian.sh`/`install.macos.sh`/`install.fedora.sh`) — rejected, triples file count across benchmarks.

**Consequences**: Package-name mappings (e.g. apt's `libncurses5-dev` vs brew's `ncurses`) are duplicated per-file instead of centralized. A future 4th OS port touches all ~29 `install.sh` files individually rather than one shared table. Revisit centralization once the macOS and Fedora ports have both landed and the duplication cost is visible in practice.

**Amendment (implementation)**: the detection mechanism landed differently than originally described above. Instead of a *sourced* helper exposing `$KOALA_OS`, detection is a standalone executable, `.tools/detect-os.sh`, invoked via command substitution and assigned to a plain `$OS`:

```sh
TOP=$(git rev-parse --show-toplevel)
OS=$("$TOP/.tools/detect-os.sh")
```

This still satisfies "single shared, not duplicated" — every script calls the same file — while avoiding sourcing's namespace pollution and keeping the call POSIX-simple. The case skeleton below should branch on `$OS`, not `$KOALA_OS`; anyone (including the concurrent Fedora port) building against the original `$KOALA_OS` name should switch to `$OS`. As of this amendment, `$OS` is wired into every `install.sh` and `setup.sh` (computed, not yet branched on — the `case` skeleton itself is still open work); it is not yet wired into `fetch.sh`/`execute.sh`/`validate.sh`/`clean.sh`, which was scoped out of this pass and left for the PATH-shim work (ADR-0002).

**Amendment 2 (case-block scope)**: now that the `case "$OS" in ... esac` skeleton has actually landed in all 18 `install.sh` files, the scope rule is: only the system-package-manager calls (`apt-get`/`brew`) go inside the branches. Steps that are OS-agnostic once a package manager has run — `pip install`, `npm install`, `cpanm`, `Rscript -e install.packages(...)`, git-clone-and-`make` builds — stay shared and unbranched below the `case`, exactly as they were before branching (this is why e.g. `bio/install.sh`'s ~170-line TERA-Seq Perl/R/binary setup is untouched by the branching, only its two apt-get blocks are). Two consequences worth knowing before touching another `install.sh`:
- A step that differs by OS in *mechanism*, not just package name (e.g. `analytics/install.sh`'s Go toolchain acquisition — a hand-rolled Linux tarball download on Debian vs. `brew install go` on macOS) goes inside the branches too, even though it isn't literally `apt-get`/`brew` on the Debian side. The dividing line is "does this step's *implementation* differ by OS," not "is this literally a package-manager invocation."
- Where a Debian-only fallback build block already exists and is guarded by `command -v x || { ...build...; }` (samtools/minimap2/nanopolish in `bio/install.sh`, seqkit's Linux-binary download in the same file), the macOS branch's job is just to make sure `x` is already on `PATH` (e.g. via `brew install`) so the guard short-circuits — not to rewrite the fallback block per OS.

`brew install` calls never use `sudo` (Homebrew installs into a user-owned prefix and warns/refuses otherwise); `sudo` stays in the debian branch only, matching apt's actual requirement. Anywhere `build-essential` was required, the macOS branch checks `xcode-select -p` and exits with an install instruction if missing, rather than trying to trigger the (GUI, non-scriptable) CLT installer itself.

GNU coreutils/gawk/sed/grep/findutils lines are omitted from every `macos)` branch — deferred entirely to ticket 03's shared PATH shim, so this ticket doesn't do ticket 03's job piecemeal per file. One latent consequence: `bio/install.sh`'s nanopolish fallback build (no brew formula exists) calls `$(nproc)`, a GNU-coreutils-only command with no macOS equivalent until ticket 03's shim lands and puts `nproc` on `PATH` — that build step won't work on macOS until then, which is expected and not a bug in this ticket's work.

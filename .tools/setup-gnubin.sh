#!/bin/sh
# Populate $TOP/.tools/gnubin with plain-named symlinks to GNU coreutils/sed/
# grep/findutils/gawk on macOS. Idempotent; never touches $PATH itself —
# callers export "$TOP/.tools/gnubin:$PATH" separately.
set -e

TOP=$(git rev-parse --show-toplevel)
GNUBIN="$TOP/.tools/gnubin"

brew install coreutils gnu-sed grep findutils gawk >/dev/null

mkdir -p "$GNUBIN"
find "$GNUBIN" -type l -delete

# coreutils/gnu-sed/grep/findutils each already publish a libexec/gnubin
# directory of plain-named symlinks (ls, sed, grep, find, xargs, ...) for
# exactly this purpose; fold all of them into one directory so callers only
# need to prepend a single path.
for formula in coreutils gnu-sed grep findutils; do
    src="$(brew --prefix "$formula")/libexec/gnubin"
    if [ -d "$src" ]; then
        for bin in "$src"/*; do
            ln -sf "$bin" "$GNUBIN/$(basename "$bin")"
        done
    fi
done

# gawk has no gnubin dir of its own — it just installs a plain `gawk` binary,
# there's no BSD awk name clash to route around at the formula level.
gawk_bin="$(brew --prefix gawk)/bin/gawk"
if [ -x "$gawk_bin" ]; then
    ln -sf "$gawk_bin" "$GNUBIN/awk"
fi

#!/bin/sh
# Puts GNU coreutils/sed/grep/findutils/gawk on PATH on macOS. No-op elsewhere.
#
# Usage: . "$TOP/.tools/macos-path.sh"
TOP=${TOP:-$(git rev-parse --show-toplevel)}
OS=${OS:-$("$TOP/.tools/detect-os.sh")}
if [ "$OS" = "macos" ]; then
    "$TOP/.tools/setup-gnubin.sh" && export PATH="$TOP/.tools/gnubin:$PATH"
fi

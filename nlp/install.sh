#!/bin/sh

TOP=$(git rev-parse --show-toplevel)
OS=$("$TOP/.tools/detect-os.sh")
if [ "$OS" = "macos" ]; then
    "$TOP/.tools/setup-gnubin.sh"
    export PATH="$TOP/.tools/gnubin:$PATH"
fi

if [ "$OS" = "fedora" ]; then
    # validate.sh's shasum is a Perl script that needs Digest::SHA, which
    # isn't in Fedora's minimal perl by default (Debian's is; macOS's shasum
    # ships as part of the base OS either way).
    sudo dnf makecache
    sudo dnf install perl-Digest-SHA -y
fi

# This benchmark does not have any other dependencies.

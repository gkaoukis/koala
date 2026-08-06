#!/bin/sh

TOP=$(git rev-parse --show-toplevel)
OS=$("$TOP/.tools/detect-os.sh")
if [ "$OS" = "macos" ]; then
    "$TOP/.tools/setup-gnubin.sh"
    export PATH="$TOP/.tools/gnubin:$PATH"
fi

# This benchmark does not have any other dependencies.

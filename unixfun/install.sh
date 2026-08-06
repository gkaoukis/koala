#!/bin/sh

TOP=$(git rev-parse --show-toplevel)

OS=$("$TOP/.tools/detect-os.sh")

if [ "$OS" = "fedora" ]; then
    sudo dnf makecache
    sudo dnf install perl-Digest-SHA -y
fi

if [ "$OS" = "macos" ]; then
    "$TOP/.tools/setup-gnubin.sh"
    export PATH="$TOP/.tools/gnubin:$PATH"
fi
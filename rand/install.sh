#!/bin/sh

TOP=$(git rev-parse --show-toplevel)
OS=$("$TOP/.tools/detect-os.sh")
if [ "$OS" = "macos" ]; then
    export PATH="$TOP/.tools/gnubin:$PATH"
fi

case "$OS" in
    debian)
        sudo apt-get update
        sudo apt-get install -y wget coreutils unzip
        ;;
    macos)
        "$TOP/.tools/setup-gnubin.sh"
        # coreutils comes from the PATH shim above
        brew install wget unzip
        ;;
    fedora)
        sudo dnf makecache
        sudo dnf install -y wget coreutils unzip
        ;;
esac

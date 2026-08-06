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
        # coreutils is provided by the ticket-03 GNU-utils PATH shim
        brew install wget unzip
        ;;
    fedora)
        sudo dnf makecache
        sudo dnf install -y wget coreutils unzip
        ;;
esac

#!/bin/sh

TOP=$(git rev-parse --show-toplevel)
OS=$("$TOP/.tools/detect-os.sh")
if [ "$OS" = "macos" ]; then
    export PATH="$TOP/.tools/gnubin:$PATH"
fi

case "$OS" in
    debian)
        pkgs="wget bsdmainutils file dos2unix grep findutils mawk"

        sudo apt-get update

        for pkg in $pkgs; do
            if ! dpkg -s "$pkg" >/dev/null 2>&1; then
                sudo apt-get install -y --no-install-recommends "$pkg"
            fi
        done
        ;;
    macos)
        "$TOP/.tools/setup-gnubin.sh"
        # grep/findutils are provided by the ticket-03 GNU-utils PATH shim.
        # bsdmainutils (hexdump/look/colcrt/...) is Debian's packaging of BSD
        # tools macOS already ships natively.
        brew install wget file dos2unix mawk
        ;;
    fedora)
        pkgs="wget util-linux file dos2unix grep findutils mawk"

        sudo dnf makecache

        for pkg in $pkgs; do
            if ! rpm -q "$pkg" >/dev/null 2>&1; then
                sudo dnf install -y "$pkg"
            fi
        done
        ;;
esac

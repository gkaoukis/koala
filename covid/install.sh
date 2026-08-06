#!/bin/sh

TOP=$(git rev-parse --show-toplevel)
OS=$("$TOP/.tools/detect-os.sh")

case "$OS" in
    debian)
        pkgs="coreutils curl gzip gawk sed git"

        sudo apt-get update

        for pkg in $pkgs; do
            if ! dpkg -s "$pkg" >/dev/null 2>&1; then
                sudo apt-get install --no-install-recommends -y "$pkg"
            fi
        done
        ;;
    macos)
        # coreutils/gawk/sed are provided by the ticket-03 GNU-utils PATH shim
        brew install curl gzip git
        ;;
    fedora)
        :
        ;;
esac

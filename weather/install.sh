#!/bin/sh

TOP=$(git rev-parse --show-toplevel)
OS=$("$TOP/.tools/detect-os.sh")

case "$OS" in
    debian)
        sudo apt-get update

        pkgs="curl wget unzip coreutils gzip gawk sed findutils git python3 python3-pip python3-venv"

        for pkg in $pkgs; do
            if ! dpkg -l | grep -q "$pkg"; then
                sudo apt-get install -y --no-install-recommends "$pkg"
            fi
        done
        ;;
    macos)
        # coreutils/gawk/sed/findutils are provided by the ticket-03 GNU-utils PATH shim
        brew install curl wget unzip gzip git python3
        ;;
    fedora)
        :
        ;;
esac

pip install --break-system-packages --upgrade pip

pip install --break-system-packages \
    numpy \
    matplotlib
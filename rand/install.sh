#!/bin/sh

TOP=$(git rev-parse --show-toplevel)
OS=$("$TOP/.tools/detect-os.sh")

case "$OS" in
    debian)
        sudo apt-get update
        sudo apt-get install -y wget coreutils unzip
        ;;
    macos)
        # coreutils is provided by the ticket-03 GNU-utils PATH shim
        brew install wget unzip
        ;;
    fedora)
        :
        ;;
esac
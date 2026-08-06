#!/bin/sh

TOP=$(git rev-parse --show-toplevel)
OS=$("$TOP/.tools/detect-os.sh")

case "$OS" in
    debian)
        sudo apt-get update
        sudo apt-get install -y \
            dc \
            coreutils \
            gawk \
            libfuse3-dev \
            fuse3 \
            pkg-config

        cd /tmp || exit 1
        git clone https://github.com/rpodgorny/unionfs-fuse.git
        cd /tmp/unionfs-fuse || exit 1
        make -j"$(nproc)"
        sudo make install
        ;;
    macos)
        # coreutils/gawk are provided by the ticket-03 GNU-utils PATH shim. dc ships
        # with the base OS already. libfuse3/unionfs-fuse are here only for
        # scripts/try.sh's nested-mount fallback; try.sh is Linux-only end to end
        # (mount -t overlay, chroot, GNU-only stat/df/mktemp flags) — see ticket 04
        # for the self-detect-and-skip candidate. Nothing else in this benchmark
        # (scripts/sieve.sh) needs libfuse3/unionfs-fuse, so they're intentionally
        # not installed here.
        brew install pkg-config
        ;;
    fedora)
        :
        ;;
esac

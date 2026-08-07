#!/bin/sh

TOP=$(git rev-parse --show-toplevel)
OS=$("$TOP/.tools/detect-os.sh")
if [ "$OS" = "macos" ]; then
    export PATH="$TOP/.tools/gnubin:$PATH"
fi

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
        if [ ! -d unionfs-fuse ]; then
            git clone https://github.com/rpodgorny/unionfs-fuse.git
        fi
        cd /tmp/unionfs-fuse || exit 1
        make -j"$(nproc)"
        sudo make install
        ;;
    macos)
        "$TOP/.tools/setup-gnubin.sh"
        # coreutils/gawk come from the PATH shim above; dc ships with the
        # base OS. libfuse3/unionfs-fuse are only for try.sh's nested-mount
        # fallback, and try.sh is Linux-only end to end (mount -t overlay,
        # chroot); not installed here.
        brew install pkg-config
        ;;
    fedora)
        sudo dnf makecache
        sudo dnf install -y \
            dc \
            coreutils \
            gawk \
            fuse3-devel \
            fuse3 \
            pkg-config

        cd /tmp || exit 1
        if [ ! -d unionfs-fuse ]; then
            git clone https://github.com/rpodgorny/unionfs-fuse.git
        fi
        cd /tmp/unionfs-fuse || exit 1
        make -j"$(nproc)"
        sudo make install
        ;;
esac

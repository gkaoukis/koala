#!/bin/sh

TOP=$(git rev-parse --show-toplevel)
OS=$("$TOP/.tools/detect-os.sh")

case "$OS" in
    fedora)
        PACKAGES="git
            gcc
            make
            ncurses-devel
            libSM-devel
            libICE-devel
            libXt-devel
            libX11-devel
            libXdmcp-devel
            libselinux-devel"
        sudo dnf makecache
        ;;
    macos)
        # git/gcc/make's roles are filled by Xcode Command Line Tools; ncurses
        # headers ship with the Xcode SDK too. The X11 libs (SM/ICE/Xt/X11/
        # Xdmcp) only matter for vim's optional GUI build (--with-x); this
        # benchmark builds vim as a console tool, and macOS has no native X11
        # server anyway (would need XQuartz) — omitted, not a build blocker.
        # libselinux is a Linux security-module header with no macOS
        # equivalent at all.
        PACKAGES=""
        if ! xcode-select -p >/dev/null 2>&1; then
            echo "Xcode Command Line Tools required: run 'xcode-select --install' first." >&2
            exit 1
        fi
        ;;
    *)
        PACKAGES="git
            gcc
            make
            libncurses-dev
            libsm-dev
            libice-dev
            libxt-dev
            libx11-dev
            libxdmcp-dev
            libselinux-dev"
        sudo apt-get update
        ;;
esac

for pkg in $PACKAGES; do
    case "$OS" in
        fedora)
            if ! rpm -q "$pkg" >/dev/null 2>&1; then
                sudo dnf install -y "$pkg"
            fi
            ;;
        macos)
            brew install "$pkg"
            ;;
        *)
            if ! dpkg -l | grep -q "^ii\s\+$pkg\s"; then
                sudo apt-get install -y --no-install-recommends "$pkg"
            fi
            ;;
    esac
done

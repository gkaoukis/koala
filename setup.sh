#!/bin/sh
set -e

TOP=$(git rev-parse --show-toplevel)
OS=$("$TOP/.tools/detect-os.sh")

# Pinned to 3.11 on every OS: .tools/requirements.txt's pins require >=3.11,
# and ml/install.sh's pins have no wheels past 3.12. Debian 12's default
# python3 already happens to be 3.11; macOS's brew `python3` is a rolling
# formula and needs the explicit pin.
PYTHON_VER="python3"

case "$OS" in
    debian)
        sudo apt-get update
        sudo apt-get install -y  git procps autoconf automake libtool build-essential cloc time gawk jq strace lsof python3.11 python3.11-venv python3-pip
        PYTHON_VER="python3.11"
        ;;
    macos)
        # build-essential's role (a C/C++ toolchain) is filled by Xcode CLT; git
        # ships with it too. procps/strace/lsof have no macOS equivalent worth
        # installing (native ps/top/lsof already cover the same ground) and are
        # only used by .tools/ dynamic-analysis tooling, not by --bare runs.
        if ! xcode-select -p >/dev/null 2>&1; then
            echo "Xcode Command Line Tools required: run 'xcode-select --install' first." >&2
            exit 1
        fi
        brew install autoconf automake libtool cloc gnu-time gawk jq python@3.11
        PYTHON_VER="python3.11"
        ;;
    fedora)
        sudo dnf makecache
        sudo dnf install -y git procps-ng autoconf automake libtool \
            gcc gcc-c++ make \
            cloc time gawk jq strace lsof \
            python3.11 \
            python3.11-devel \
            python3-pip
        PYTHON_VER="python3.11"
        ;;
esac

cd "$(dirname "$0")" || exit 1
cd "$(pwd -P)" || exit 1

VENV_DIR="$TOP/venv"
rm -rf "$VENV_DIR"
$PYTHON_VER -m venv "$VENV_DIR"
# shellcheck disable=SC1091
. "$VENV_DIR/bin/activate"

pip install --upgrade pip
pip install --break-system-packages -r "$TOP/.tools/requirements.txt"

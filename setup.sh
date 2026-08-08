#!/bin/sh
set -e

TOP=$(git rev-parse --show-toplevel)
OS=$("$TOP/.tools/detect-os.sh")

PYTHON_VER="python3"

case "$OS" in
    debian)
        sudo apt-get update
        sudo apt-get install -y  git procps autoconf automake libtool build-essential cloc time gawk jq strace lsof python3.11 python3.11-venv python3-pip
        PYTHON_VER="python3.11"
        ;;
    macos)
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

. "$TOP/.tools/macos-path.sh"

cd "$(dirname "$0")" || exit 1
cd "$(pwd -P)" || exit 1

VENV_DIR="$TOP/venv"
rm -rf "$VENV_DIR"
$PYTHON_VER -m venv "$VENV_DIR"

. "$VENV_DIR/bin/activate"

pip install --upgrade pip
pip install --break-system-packages -r "$TOP/.tools/requirements.txt"

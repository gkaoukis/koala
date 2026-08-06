#!/bin/sh
set -e

cd "$(realpath "$(dirname "$0")")" || exit 1

TOP=$(git rev-parse --show-toplevel)
OS=$("$TOP/.tools/detect-os.sh")

case "$OS" in
    debian)
        sudo apt-get update
        sudo apt-get install -y  git procps autoconf automake libtool build-essential cloc time gawk jq strace lsof python3 python3-pip python3-venv
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
        brew install autoconf automake libtool cloc gnu-time gawk jq python3
        ;;
    fedora)
        :
        ;;
esac

VENV_DIR="$TOP/venv"
rm -rf "$VENV_DIR"
python3 -m venv "$VENV_DIR"
# shellcheck disable=SC1091
. "$VENV_DIR/bin/activate"

pip install --upgrade pip
pip install --break-system-packages -r "$TOP/.tools/requirements.txt"

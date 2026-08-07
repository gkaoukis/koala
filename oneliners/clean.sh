#!/bin/sh


TOP=$(git rev-parse --show-toplevel)
OS=$("$TOP/.tools/detect-os.sh")
if [ "$OS" = "macos" ]; then
    export PATH="$TOP/.tools/gnubin:$PATH"
fi

for arg in "$@"; do
    case "$arg" in
        "-f") force=true ;;
    esac
done

cd "$(realpath "$(dirname "$0")")" || exit 1
rm -rf ./outputs

if [ "$force" = true ]; then
    rm -rf ./inputs
fi

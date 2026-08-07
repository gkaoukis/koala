#!/bin/sh


TOP=$(git rev-parse --show-toplevel)
OS=$("$TOP/.tools/detect-os.sh")
if [ "$OS" = "macos" ]; then
    export PATH="$TOP/.tools/gnubin:$PATH"
fi

cd "$(realpath "$(dirname "$0")")" || exit 1

for arg in "$@"; do
    case "$arg" in
        "-f") force=true ;;
    esac
done

rm -rf ./outputs

if [ "$force" = true ]; then
    rm -rf ./tmp
    rm -rf ./inputs
fi

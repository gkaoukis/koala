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

TOP=$(git rev-parse --show-toplevel)
input_dir="${TOP}/interact/inputs"
outputs_dir="${TOP}/interact/outputs"

rm -rf "$outputs_dir"
if [ "$force" = true ]; then
    rm -rf "$input_dir"
fi
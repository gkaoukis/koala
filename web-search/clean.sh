#!/bin/sh


TOP=$(git rev-parse --show-toplevel)
OS=$("$TOP/.tools/detect-os.sh")
if [ "$OS" = "macos" ]; then
    export PATH="$TOP/.tools/gnubin:$PATH"
fi

cd "$(dirname "$0")" || exit 1

for arg in "$@"; do
    case "$arg" in
        "-f") force=true ;;
    esac
done

eval_dir="$PWD"
outputs_dir="${eval_dir}/outputs"
input_dir="${eval_dir}/inputs"
tmp_dir="${eval_dir}/tmp"

rm -rf "$outputs_dir"
rm -rf "$tmp_dir"

if [ "$force" = true ]; then
    rm -rf "$input_dir"
fi


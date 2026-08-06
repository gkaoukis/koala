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
eval_dir="$TOP/inference"
input_dir="$eval_dir/inputs"
outputs_dir="$eval_dir/outputs"

rm -rf "$outputs_dir"
rm -f "$eval_dir/ollama_serve.log"
if [ "$force" = true ]; then
    rm -rf "$input_dir"
fi


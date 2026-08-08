#!/bin/sh
# Ensures `uv` is on PATH, installing it if missing. Same install method on
# every OS (uv's own installer detects platform/arch) — no case statement.
# Must be sourced, not executed: . "$TOP/.tools/ensure-uv.sh"
if ! command -v uv >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

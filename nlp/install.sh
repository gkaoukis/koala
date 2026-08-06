#!/bin/sh

TOP=$(git rev-parse --show-toplevel)
# shellcheck disable=SC2034
OS=$("$TOP/.tools/detect-os.sh")

# This benchmark does not have any dependencies.

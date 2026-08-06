#!/bin/sh
#
# Prints one of: debian, macos, fedora, unknown
#
# Usage: OS=$($TOP/.tools/detect-os.sh)

if [ "$(uname -s)" = "Darwin" ]; then
    echo "macos"
    exit 0
fi

if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    os_release_id="$( (. /etc/os-release && echo "$ID $ID_LIKE") 2>/dev/null)"
    case "$os_release_id" in
        *debian*|*ubuntu*)
            echo "debian"
            exit 0
            ;;
        *fedora*|*rhel*)
            echo "fedora"
            exit 0
            ;;
    esac
fi

if command -v apt-get >/dev/null 2>&1; then
    echo "debian"
    exit 0
fi

if command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
    echo "fedora"
    exit 0
fi

echo "unknown"
exit 0

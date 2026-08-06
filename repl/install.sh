#!/bin/sh

TOP=$(git rev-parse --show-toplevel)
OS=$("$TOP/.tools/detect-os.sh")

case "$OS" in
    debian)
        sudo apt-get update

        pkgs="bash curl grep gawk iptables ufw procps net-tools fail2ban iproute2 git patch time"

        for pkg in $pkgs; do
            if ! dpkg -l | grep -q "^ii  $pkg "; then
                sudo apt-get install -y --no-install-recommends "$pkg"
            fi
        done
        ;;
    macos)
        # grep/gawk are provided by the ticket-03 GNU-utils PATH shim. iptables/ufw/
        # procps/net-tools/fail2ban/iproute2 exist here solely for
        # scripts/vps-audit.sh + vps-audit-negate.sh, which are confirmed Linux-only
        # (dpkg -l, apt-get -s upgrade, /proc, /sys, Linux-specific sysctl keys) —
        # see ticket 04. scripts/git-workflow.sh (the only other script here) needs
        # only bash/git/patch/time, all mapped below.
        brew install bash curl git gpatch gnu-time
        ;;
    fedora)
        sudo dnf makecache

        pkgs="bash curl grep gawk iptables procps-ng net-tools fail2ban iproute git patch time"

        for pkg in $pkgs; do
            if ! rpm -q "$pkg" >/dev/null 2>&1; then
                sudo dnf install -y "$pkg"
            fi
        done
        ;;
esac

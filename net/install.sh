#!/bin/sh

TOP=$(git rev-parse --show-toplevel)
OS=$("$TOP/.tools/detect-os.sh")

case "$OS" in
    debian)
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --yes --dearmor -o /etc/apt/keyrings/charm.gpg
        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list

        sudo apt-get update -y

        sudo apt-get install -y \
            build-essential \
            git \
            curl \
            wget \
            gpg \
            automake \
            flex \
            tar \
            libpq-dev \
            libpcre3-dev \
            libssl-dev \
            libpcap-dev \
            libltdl-dev \
            bison \
            python3 \
            python3-pip \
            python3-venv \
            net-tools \
            xsltproc \
            bind9-dnsutils \
            netcat-traditional

        sudo apt-get install -y \
            nmap \
            lolcat \
            masscan \
            bind9-host \
            geoip-bin \
            hwinfo \
            autoconf \
            iproute2 \
            iptables \
            ipset \
            masscan \
            postgresql \
            postgresql-contrib \
            check \
            iputils-ping
        ;;
    macos)
        # This benchmark is out of scope for macOS validation (spec: net/execute.sh
        # manipulates live firewall/NAT rules directly) and net/execute.sh uses Linux
        # network namespaces (`ip netns`, veth pairs), which have no macOS kernel
        # equivalent at all. Dependencies are still mapped below per request, but note
        # what genuinely has no macOS equivalent:
        #   - iptables: brew has a formula, but it doesn't control macOS's firewall
        #     (pf), so it installs without being functionally useful here.
        #   - ipset, iproute2, net-tools, hwinfo: Linux-kernel/procfs-specific tools
        #     with no brew formula and no macOS equivalent; omitted.
        #   - geoip-bin: no matching brew formula found (geoipupdate is a different
        #     tool, for updating MaxMind DB files, not the CLI lookup utility);
        #     omitted.
        #   - the repo.charm.sh apt keyring/source setup at the top of the debian
        #     branch installs nothing from that repo anywhere in this benchmark
        #     (grepped net/scripts/*.sh) — vestigial, not ported.
        if ! xcode-select -p >/dev/null 2>&1; then
            echo "Xcode Command Line Tools required: run 'xcode-select --install' first." >&2
            exit 1
        fi
        brew install git curl wget gnupg automake flex gnu-tar libpq pcre openssl libpcap \
            libtool bison python3 libxslt bind netcat nmap lolcat masscan postgresql \
            check iputils
        ;;
    fedora)
        # Same out-of-scope caveats as the macos branch above re: this benchmark's
        # Linux-kernel-specific network namespace / iptables usage — packages are
        # still mapped below per the upstream Fedora port. The repo.charm.sh apt
        # keyring/source setup in the debian branch is apt-specific and skipped here.
        sudo dnf makecache

        sudo dnf install -y \
            gcc \
            gcc-c++ \
            make \
            git \
            curl \
            wget \
            gpg \
            automake \
            flex \
            tar \
            postgresql-devel \
            pcre-devel \
            openssl-devel \
            libpcap-devel \
            libtool-ltdl-devel \
            bison \
            python3 \
            python3-pip \
            python3-virtualenv \
            net-tools \
            libxslt \
            bind-utils \
            nc \
            nmap \
            lolcat \
            masscan \
            bind \
            geoip \
            hwinfo \
            autoconf \
            iproute \
            iptables \
            ipset \
            postgresql-server \
            postgresql-contrib \
            check \
            iputils
        ;;
esac

#!/bin/sh

TOP=$(git rev-parse --show-toplevel)
OS=$("$TOP/.tools/detect-os.sh")

case "$OS" in
    debian)
        sudo apt-get update

        sudo apt-get install -y --no-install-recommends  gpg \
            wget \
            git \
            unzip \
            zip \
            zstd \
            libncurses5-dev \
            libncursesw5-dev \
            zstd \
            liblzma-dev \
            libbz2-dev \
            zip \
            unzip \
            nodejs \
            libarchive-tools \
            ffmpeg \
            unrtf \
            imagemagick \
            tcpdump \
            cmake \
            build-essential \
            libssl-dev \
            qtcreator qtbase5-dev qt5-qmake gcc libtirpc-dev \
            make \
            libncurses-dev \
            libsm-dev \
            libice-dev \
            libxt-dev \
            libx11-dev \
            libxdmcp-dev \
            libselinux-dev \
            libtool \
            libtool-bin \
            libreadline-dev \
            npm

        wget -qO - 'https://proget.makedeb.org/debian-feeds/makedeb.pub' | gpg --dearmor | sudo tee /usr/share/keyrings/makedeb-archive-keyring.gpg > /dev/null
        echo 'deb [signed-by=/usr/share/keyrings/makedeb-archive-keyring.gpg arch=all] https://proget.makedeb.org/ makedeb main' | sudo tee /etc/apt/sources.list.d/makedeb.list > /dev/null

        sudo apt-get update
        sudo apt-get install -y --no-install-recommends makedeb

        # Install Node.js (18.x) and npm via NodeSource, if the earlier apt install
        # of nodejs somehow didn't take
        if ! command -v node > /dev/null 2>&1 ; then
          curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
          sudo apt-get install -y --no-install-recommends nodejs
        fi

        sudo apt-get install -y --no-install-recommends  default-jdk
        ;;
    macos)
        # Everything above beyond nodejs/npm (Qt, X11 dev libs, ncurses, SELinux,
        # RPC libs, makedeb itself, ...) exists solely to let makedeb build
        # arbitrary PKGBUILDs for scripts/pacaur.sh. makedeb has no macOS support
        # at all (see ticket 04 — pacaur.sh self-detects and skips on macOS), so
        # none of that is needed here. scripts/proginf.sh (the only other script
        # in this benchmark) is a plain Node.js tool — node is all it needs.
        # default-jdk (installed in the debian branch above) is unused by both
        # scripts (grepped pkg/scripts/*.sh for java/jdk/.jar) and is likewise a
        # makedeb-only dependency; omitted here.
        brew install node
        ;;
    fedora)
        # makedeb has no Fedora support either (Debian-packaging-specific), so it's
        # skipped here too — see the macos branch's comment above for why the rest
        # of makedeb's build dependencies (Qt, X11 dev libs, ncurses, SELinux, RPC
        # libs, ...) only matter for scripts/pacaur.sh, which is Linux/apt-only.
        sudo dnf makecache

        sudo dnf install -y \
            gpg \
            wget \
            git \
            unzip \
            zip \
            zstd \
            nodejs \
            ffmpeg \
            unrtf \
            tcpdump \
            cmake \
            gcc \
            gcc-c++ \
            make \
            libtool \
            npm \
            ncurses-devel \
            xz-devel \
            bzip2-devel \
            libarchive \
            ImageMagick \
            openssl-devel \
            qt-creator \
            qt5-qtbase-devel \
            libtirpc-devel \
            libSM-devel \
            libICE-devel \
            libXt-devel \
            libX11-devel \
            libXdmcp-devel \
            libselinux-devel \
            readline-devel \
            java-latest-openjdk-devel

        # Install Node.js, if the earlier dnf install of nodejs somehow didn't take
        if ! command -v node > /dev/null 2>&1 ; then
          sudo dnf install -y nodejs
        fi
        ;;
esac

TOP=$(git rev-parse --show-toplevel)
URL="https://atlas.cs.brown.edu/data"
installdir="$TOP/pkg/inputs"

mkdir -p "$installdir"
cd "$installdir" || exit 1
# Install mir-sa
if [ ! -d mir-sa ]; then
  wget "$URL/prog-inf/mir-sa.tar.gz" -O mir-sa.tar.gz
  tar xf mir-sa.tar.gz --no-same-owner
  rm mir-sa.tar.gz
fi

cd mir-sa/@andromeda/mir-sa || exit 1
if [ ! -d node_modules ]; then
  npm install
fi

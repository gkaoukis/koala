#!/bin/sh

TOP=$(git rev-parse --show-toplevel)
OS=$("$TOP/.tools/detect-os.sh")
if [ "$OS" = "macos" ]; then
    export PATH="$TOP/.tools/gnubin:$PATH"
fi

case "$OS" in
    debian)
        sudo apt-get update

        sudo apt-get install -y --no-install-recommends \
            python3 \
            python3-pip \
            python3-venv \
            libgl1 \
            libglib2.0-0 \
            libjpeg-dev \
            zstd \
            ffmpeg \
            procps \
            coreutils findutils wget sed unzip curl jq coreutils findutils sed unzip curl imagemagick
        ;;
    macos)
        "$TOP/.tools/setup-gnubin.sh"
        # coreutils/findutils/sed are provided by the ticket-03 GNU-utils PATH shim.
        # libgl1/libglib2.0-0 satisfy Linux (X11/Mesa) wheel deps for torch/tensorflow/
        # opencv-python; their macOS wheels link against system frameworks instead, so
        # there's no brew equivalent needed here.
        brew install python3 jpeg zstd ffmpeg procps wget unzip curl jq imagemagick
        ;;
    fedora)
        sudo dnf makecache

        sudo dnf install -y \
            python3 \
            python3-pip \
            python3-virtualenv \
            zstd \
            ffmpeg \
            coreutils \
            findutils \
            wget \
            sed \
            unzip \
            curl \
            jq \
            procps-ng \
            mesa-libGL \
            glib2 \
            libjpeg-turbo-devel \
            ImageMagick \
            perl-Digest-SHA
        ;;
esac

pip install --break-system-packages --upgrade pip
pip install --break-system-packages llm
pip install --break-system-packages llm-interpolate
pip install --break-system-packages llm-clap
pip install --break-system-packages llm-ollama

pip install --break-system-packages numpy \
    torch \
    torchvision \
    Pillow \
    segment-anything \
    tensorflow \
    opencv-python

# check if ollama is installed
if ! command -v ollama >/dev/null 2>&1
then
    echo "Ollama could not be found, installing..."
    curl -fsSL https://ollama.com/install.sh | sh
    # On macOS the installer places the CLI at /usr/local/bin/ollama (as a symlink
    # into /Applications/Ollama.app), but a non-interactive shell's default PATH
    # doesn't include /usr/local/bin, so `command -v ollama` below would still miss
    # it. This is harmless to prepend on any OS.
    export PATH="/usr/local/bin:$PATH"
else
    echo "Ollama is already installed."
fi

ollama serve > /dev/null 2>&1 &
sleep 5
ollama pull moondream:latest

ollama_pid=$(pgrep ollama)
if [ -n "$ollama_pid" ]; then
    kill "$ollama_pid"
fi

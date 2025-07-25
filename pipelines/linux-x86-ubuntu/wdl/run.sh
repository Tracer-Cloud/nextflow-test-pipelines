#!/bin/bash
set -e

# --- Minimal Docker install and setup (Ubuntu) ---
if ! command -v docker &> /dev/null; then
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        SUDO=""
    fi
    $SUDO apt-get update
    $SUDO apt-get install -y docker.io
    $SUDO systemctl enable --now docker
fi

if ! getent group docker > /dev/null; then
    sudo groupadd docker
fi
sudo usermod -aG docker $USER

# If using snap, restart docker
if snap list | grep -q docker; then
    sudo snap restart docker
fi

newgrp docker <<EONG
set -e

# Test Docker access
if ! docker ps > /dev/null 2>&1; then
    echo 'Docker permission issue persists. Please log out and log back in, or restart your shell.'
    exit 1
fi

install_pixi() {
    echo "Pixi not found. Installing Pixi..."
    curl -fsSL https://pixi.sh/install.sh | bash
    export PATH="$HOME/.pixi/bin:$PATH"
    echo "Pixi installed successfully!"
}

if ! command -v pixi &> /dev/null; then
    install_pixi
fi

if [ -n "$ZSH_VERSION" ]; then
    SHELL_PROFILE="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_PROFILE="$HOME/.bashrc"
else
    SHELL_PROFILE="$HOME/.profile"
fi

if [ -f "$SHELL_PROFILE" ]; then
    echo "Sourcing $SHELL_PROFILE before running pixi..."
    source "$SHELL_PROFILE"
fi

echo "Running Tracer WDL Minimal pipeline with miniwdl"
pixi run --manifest-path ../../shared/wdl/pixi.toml script
EONG

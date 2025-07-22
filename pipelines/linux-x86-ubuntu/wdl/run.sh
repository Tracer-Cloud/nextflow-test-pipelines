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
    # Only try to add user to docker group if not already root
    if [ "$(id -u)" -ne 0 ]; then
        $SUDO usermod -aG docker $USER
        echo "Docker installed. You may need to log out and log back in for group changes to take effect."
    fi
fi

if ! docker info &> /dev/null; then
    echo "Docker is not running or you do not have permission to access it."
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

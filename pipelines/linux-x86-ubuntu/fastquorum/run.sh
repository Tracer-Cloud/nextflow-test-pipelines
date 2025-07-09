#!/usr/bin/env bash
set -e

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

echo "Running nf-core/fastquorum pipeline..."
pixi run --manifest-path ../../shared/fastquorum/pixi.toml pipeline

echo "Pipeline completed successfully!"
echo "Results are available in the 'results' directory"
echo "Logs are available in the 'logs' directory"

#!/usr/bin/env bash
set -euo pipefail

ENV_NAME="linux-x86-amazon-minimal"
CONDA_HOME="$HOME/miniconda"
ENV_YML="environment.yml"

# --- Swap Setup (only if not already present) ---
if ! grep -q '/swapfile' /proc/swaps && [ ! -f /swapfile ]; then
    echo "[INFO] Creating 2GB swap file..."
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
else
    echo "[INFO] Swap file already exists. Skipping swap creation."
fi

# --- Install Miniconda if missing ---
if [ ! -d "$CONDA_HOME" ]; then
    echo "[INFO] Installing Miniconda (x86_64)..."
    wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
    bash miniconda.sh -b -p "$CONDA_HOME"
    rm miniconda.sh
    echo 'export PATH="$HOME/miniconda/bin:$PATH"' >> "$HOME/.bashrc"
    "$CONDA_HOME/bin/conda" init bash

    echo "[INFO] Miniconda installed. Please restart your shell or run 'source ~/.bashrc'"
fi

# --- Load Conda ---
export PATH="$CONDA_HOME/bin:$PATH"
eval "$("$CONDA_HOME/bin/conda" shell.bash hook)"

# --- Accept Conda Terms of Service ---
conda config --set channel_priority strict
conda config --remove channels defaults || true
conda config --add channels conda-forge
conda config --add channels bioconda

# --- Check if environment exists ---
if conda info --envs | grep -q "^$ENV_NAME "; then
    echo "[INFO] Conda environment '$ENV_NAME' already exists. Skipping creation."
else
    echo "[INFO] Creating Conda environment '$ENV_NAME' from $ENV_YML..."
    conda env create -n "$ENV_NAME" -f "$ENV_YML"
fi

# --- Activate environment ---
conda activate "$ENV_NAME"

# --- Ensure log/output dirs exist ---
mkdir -p logs results


# --- Run Nextflow pipeline ---
echo "[INFO] Running Nextflow pipeline..."
nextflow -log logs/nextflow.log run main.nf --outdir results

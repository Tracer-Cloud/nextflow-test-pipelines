#!/usr/bin/env bash
set -e

echo "[INFO] Setting up conda environment for codespaces..."

# Check if conda is available in the system PATH first
if command -v conda &> /dev/null; then
    echo "[INFO] Conda found in system PATH"
    CONDA_CMD="conda"
elif [ -f "/opt/conda/bin/conda" ]; then
    echo "[INFO] Using system conda at /opt/conda/bin/conda"
    export PATH="/opt/conda/bin:$PATH"
    CONDA_CMD="/opt/conda/bin/conda"
elif [ -f "$HOME/miniconda/bin/conda" ]; then
    echo "[INFO] Using miniconda at $HOME/miniconda/bin/conda"
    export PATH="$HOME/miniconda/bin:$PATH"
    CONDA_CMD="$HOME/miniconda/bin/conda"
else
    echo "[INFO] Installing Miniconda..."
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
    bash miniconda.sh -b -p "$HOME/miniconda"
    export PATH="$HOME/miniconda/bin:$PATH"
    CONDA_CMD="$HOME/miniconda/bin/conda"
    
    # Initialize conda
    "$CONDA_CMD" init bash
    source "$HOME/.bashrc" 2>/dev/null || true
fi

# Initialize conda for current shell
eval "$($CONDA_CMD shell.bash hook)"
mkdir -p logs

# Check if environment exists, if not create it
if conda env list | grep -q "^rnaseq-minimal[[:space:]]"; then
    echo "[INFO] Conda environment 'rnaseq-minimal' already exists. Updating it..."
    conda env update -f environment.yml
else
    echo "[INFO] Creating conda environment 'rnaseq-minimal'..."
    conda env create -f environment.yml
fi

# Activate the environment
echo "[INFO] Activating conda environment..."
conda activate rnaseq-minimal

# Verify tools are available
echo "[INFO] Verifying tools are available..."
fastqc --version || echo "Warning: FastQC not found"
STAR --version || echo "Warning: STAR not found"
samtools sort --version || echo "Warning: Samtools not found"
nextflow --version || echo "Warning: Nextflow not found"

# Run the pipeline
echo "[INFO] Running Nextflow pipeline..."
nextflow -log logs/nextflow.log run main.nf --outdir results

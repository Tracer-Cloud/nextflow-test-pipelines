#!/usr/bin/env bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}[INFO]${NC} Setting up Nextflow pipeline with Pixi for macOS..."

# Install Homebrew if not present
if ! command -v brew &> /dev/null; then
    echo -e "${BLUE}[INFO]${NC} Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH
    if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# Install pixi via Homebrew
if ! command -v pixi &> /dev/null; then
    echo -e "${BLUE}[INFO]${NC} Installing Pixi via Homebrew..."
    brew install pixi
fi

# Setup pixi environment
echo -e "${BLUE}[INFO]${NC} Setting up Pixi environment..."
if [ -f "pixi.toml" ]; then
    pixi install
else
    echo -e "${RED}[ERROR]${NC} pixi.toml not found"
    exit 1
fi

# Create test data if needed
mkdir -p test_data logs results test_results
if [ ! -f "test_data/sample1.fasta" ]; then
    echo -e "${BLUE}[INFO]${NC} Creating sample test data..."
    cat > test_data/sample1.fasta << 'EOF'
>seq1
ATCGATCGATCG
>seq2
GCTAGCTAGCTA
EOF
fi

# Run pipeline
echo -e "${BLUE}[INFO]${NC} Running Nextflow pipeline..."
if pixi run test; then
    echo -e "${GREEN}[SUCCESS]${NC} Pipeline completed! Results in: test_results/"
else
    echo -e "${RED}[ERROR]${NC} Pipeline failed. Check logs/nextflow.log"
    exit 1
fi

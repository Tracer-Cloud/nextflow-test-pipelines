#!/bin/bash

# Codespaces Pixi Pipeline Runner
# This script sets up and runs a Nextflow pipeline using Pixi in GitHub Codespaces
# Based on the macOS ARM64 Pixi example, adapted for Linux

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Main script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PIPELINE_DIR="$SCRIPT_DIR/nextflow-pixi-linux"

print_status "Starting Codespaces Pixi Pipeline Setup"
print_status "Script directory: $SCRIPT_DIR"
print_status "Workspace root: $WORKSPACE_ROOT"
print_status "Pipeline directory: $PIPELINE_DIR"

# Step 1: Install Pixi if not already installed
print_status "Checking Pixi installation..."
if ! command_exists pixi; then
    print_status "Installing Pixi..."
    curl -fsSL https://pixi.sh/install.sh | bash
    
    # Add Pixi to PATH for current session
    export PATH="$HOME/.pixi/bin:$PATH"
    
    # Verify installation
    if command_exists pixi; then
        print_success "Pixi installed successfully"
        pixi --version
    else
        print_error "Failed to install Pixi"
        exit 1
    fi
else
    print_success "Pixi is already installed"
    pixi --version
fi

# Step 2: Install Nextflow if not already installed
print_status "Checking Nextflow installation..."
if ! command_exists nextflow; then
    print_status "Installing Nextflow..."
    curl -s https://get.nextflow.io | bash
    sudo mv nextflow /usr/local/bin/ || mv nextflow "$HOME/.local/bin/" 2>/dev/null || {
        mkdir -p "$HOME/bin"
        mv nextflow "$HOME/bin/"
        export PATH="$HOME/bin:$PATH"
    }
    
    # Verify installation
    if command_exists nextflow; then
        print_success "Nextflow installed successfully"
        nextflow -v
    else
        print_error "Failed to install Nextflow"
        exit 1
    fi
else
    print_success "Nextflow is already installed"
    nextflow -v
fi

# Step 3: Create Linux-compatible pipeline directory
print_status "Setting up Linux-compatible Pixi pipeline..."
mkdir -p "$PIPELINE_DIR"

# Copy and adapt the macOS ARM64 pipeline files
MACOS_PIPELINE="$WORKSPACE_ROOT/pipelines/macos-arm64/nextflow-pixi"

if [ ! -d "$MACOS_PIPELINE" ]; then
    print_error "macOS ARM64 pipeline not found at: $MACOS_PIPELINE"
    exit 1
fi

# Copy main pipeline files
cp "$MACOS_PIPELINE/main.nf" "$PIPELINE_DIR/"
cp "$MACOS_PIPELINE/nextflow.config" "$PIPELINE_DIR/"
cp "$MACOS_PIPELINE/run.sh" "$PIPELINE_DIR/"

# Copy test data
cp -r "$MACOS_PIPELINE/test_data" "$PIPELINE_DIR/" 2>/dev/null || {
    print_warning "Test data not found, creating sample data..."
    mkdir -p "$PIPELINE_DIR/test_data"
    
    # Create sample FASTA files
    cat > "$PIPELINE_DIR/test_data/sample1.fasta" << 'EOF'
>sequence1
ATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCG
ATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCG
>sequence2
GCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCT
GCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCT
EOF

    cat > "$PIPELINE_DIR/test_data/sample2.fasta" << 'EOF'
>sequence3
TTAATTAATTAATTAATTAATTAATTAATTAATTAATTAATTAATTAATTAATTAATTAA
TTAATTAATTAATTAATTAATTAATTAATTAATTAATTAATTAATTAATTAATTAATTAA
>sequence4
CCGGCCGGCCGGCCGGCCGGCCGGCCGGCCGGCCGGCCGGCCGGCCGGCCGGCCGGCCGG
CCGGCCGGCCGGCCGGCCGGCCGGCCGGCCGGCCGGCCGGCCGGCCGGCCGGCCGGCCGG
EOF
    
    print_success "Created sample test data"
}

# Step 4: Create Linux-compatible pixi.toml
print_status "Creating Linux-compatible pixi.toml..."
cat > "$PIPELINE_DIR/pixi.toml" << 'EOF'
[workspace]
name = "nextflow-minimal-pixi-linux"
description = "Minimal Nextflow pipeline using Pixi for dependency management (Linux/Codespaces)"
version = "1.0.0"
authors = ["Tracer Bioinformatics Team"]
channels = ["conda-forge", "bioconda"]
platforms = ["linux-64"]

[dependencies]
# Core bioinformatics tools
fastqc = "0.12.1"
star = "2.7.11b"

# System utilities
coreutils = "9.1"
bc = "*"

# Development and debugging tools (optional)
tree = "*"
nextflow = ">=25.4.4,<26"

[tasks]
# Setup task - prepare environment and test data
setup = "echo 'Environment ready! Use: pixi run pipeline'"

# Main pipeline execution
pipeline = "bash run.sh"

# Run with custom parameters
pipeline-custom = "bash run.sh --input custom_data/*.fasta --outdir custom_results"

# Development tasks
test = "pixi run pipeline --input test_data/*.fasta --outdir test_results"
clean = """
rm -rf results logs work test_results custom_results
rm -f .nextflow* 2>/dev/null || true
echo "✅ Cleaned up all results and logs"
"""

# Development workflow (runs tasks in sequence)
dev = """
echo "=== Development Workflow ==="
pixi run clean
pixi run setup
pixi run test
echo "=== Development Workflow Complete ==="
"""
EOF

print_success "Created Linux-compatible pixi.toml"

# Step 5: Navigate to pipeline directory and install dependencies
print_status "Installing Pixi dependencies..."
cd "$PIPELINE_DIR"

# Install dependencies
pixi install

print_success "Dependencies installed successfully"

# Step 6: Run the pipeline
print_status "Running the Nextflow pipeline..."
pixi run test

# Step 8: Display results
print_success "Pipeline completed successfully!"
print_status "Results are available in:"
echo "  - $(pwd)/test_results/fasta_stats/ - Detailed statistics"
echo "  - $(pwd)/test_results/counts/ - Sequence counts"
echo "  - $(pwd)/logs/ - Pipeline logs and reports"

if [ -d "test_results" ]; then
    print_status "Pipeline output summary:"
    find test_results -name "*.txt" -exec echo "  - {}" \; -exec head -3 {} \; -exec echo "" \;
fi

print_success "Codespaces Pixi Pipeline completed successfully!"
print_status "You can now explore the results or run additional commands:"
echo "  pixi run pipeline      # Run with default data"
echo "  pixi run clean         # Clean up results"

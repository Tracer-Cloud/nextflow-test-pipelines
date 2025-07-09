#!/usr/bin/env bash
set -e

# Function to install pixi if not found
install_pixi() {
    echo "Pixi not found. Installing Pixi..."
    curl -fsSL https://pixi.sh/install.sh | bash
    export PATH="$HOME/.pixi/bin:$PATH"
    echo "Pixi installed successfully!"
}

# Check if pixi is available
if ! command -v pixi &> /dev/null; then
    install_pixi
fi

# Determine shell profile based on current shell
if [ -n "$ZSH_VERSION" ]; then
    SHELL_PROFILE="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_PROFILE="$HOME/.bashrc"
else
    SHELL_PROFILE="$HOME/.profile"
fi

# Source shell profile if it exists to ensure pixi is in PATH
if [ -f "$SHELL_PROFILE" ]; then
    echo "Sourcing $SHELL_PROFILE before running pixi..."
    source "$SHELL_PROFILE"
fi

# Create necessary directories
mkdir -p logs results test_data

# Generate test data if it doesn't exist
if [ ! -f "test_data/AEG588A1_S1_L002_R1_001.fastq.gz" ]; then
    echo "Generating test data..."
    mkdir -p test_data
    
    # R1 file
    cat > test_data/AEG588A1_S1_L002_R1_001.fastq << 'EOF'
@SRR001666.1 071112_SLXA-EAS1_s_7:5:1:817:345 length=36
GGGTGATGGCCGCTGCCGATGGCGTCAAATCCCACC
+SRR001666.1 071112_SLXA-EAS1_s_7:5:1:817:345 length=36
IIIIIIIIIIIIIIIIIIIIIIIIIIIIII9IG9IC
@SRR001666.2 071112_SLXA-EAS1_s_7:5:1:817:345 length=36
GTTCAGGGATACGACGTTTGTATTTTAAGAATCTGA
+SRR001666.2 071112_SLXA-EAS1_s_7:5:1:817:345 length=36
IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII6IBI
EOF

    # R2 file
    cat > test_data/AEG588A1_S1_L002_R2_001.fastq << 'EOF'
@SRR001666.1 071112_SLXA-EAS1_s_7:5:1:817:345 length=36
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
+SRR001666.1 071112_SLXA-EAS1_s_7:5:1:817:345 length=36
IIIIIIIIIIIIIIIIIIIIIIIIIIIIII9IG9IC
@SRR001666.2 071112_SLXA-EAS1_s_7:5:1:817:345 length=36
GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG
+SRR001666.2 071112_SLXA-EAS1_s_7:5:1:817:345 length=36
IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII6IBI
EOF

    gzip test_data/AEG588A1_S1_L002_R1_001.fastq
    gzip test_data/AEG588A1_S1_L002_R2_001.fastq
    
    echo "Test data created successfully!"
fi

echo "Creating samplesheet.csv..."
cat > samplesheet.csv << 'EOF'
sample,fastq_1,fastq_2,read_structure
CONTROL_REP1,test_data/AEG588A1_S1_L002_R1_001.fastq.gz,test_data/AEG588A1_S1_L002_R2_001.fastq.gz,5M2S+T 5M2S+T
EOF

echo "Installing dependencies with pixi..."
pixi install

echo "Running nf-core/fastquorum pipeline..."

nextflow run nf-core/fastquorum \
    -profile docker \
    --input samplesheet.csv \
    --outdir results \
    --genome GRCh38

echo "Pipeline completed successfully!"
echo "Results are available in the 'results' directory"
echo "Logs are available in the 'logs' directory" 
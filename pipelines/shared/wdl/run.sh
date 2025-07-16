#!/bin/bash
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

# Create data directory if it doesn't exist
mkdir -p data

# Generate minimal FASTQ files if they do not exist
if [ ! -f data/sample_R1.fastq ]; then
  echo -e "@SEQ_ID\nGATTTGGGGTTTAAAGGG\n+\n!''*((((***+))%%%++)(%%%%).1***-+*''))**55CCF>>>>>>CCCCCCC65" > data/sample_R1.fastq
fi
if [ ! -f data/sample_R2.fastq ]; then
  echo -e "@SEQ_ID\nCCCTTTAAACCCCAAATC\n+\n!''*((((***+))%%%++)(%%%%).1***-+*''))**55CCF>>>>>>CCCCCCC65" > data/sample_R2.fastq
fi

# Generate minimal BAM file if it does not exist
if [ ! -f data/test.bam ]; then
  if command -v samtools >/dev/null 2>&1; then
    echo -e "@HD\tVN:1.0\tSO:unsorted\n@SQ\tSN:chr1\tLN:1000\nread1\t0\tchr1\t1\t255\t10M\t*\t0\t0\tACGTACGTAC\t*" > data/minimal.sam
    samtools view -bS data/minimal.sam > data/test.bam
    rm data/minimal.sam
  else
    # Fallback: create a placeholder BAM (not valid for real analysis)
    echo "BAMPLACEHOLDER" > data/test.bam
  fi
fi


echo "Running Tracer WDL Minimal pipeline"
pixi run pipeline

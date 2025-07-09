# FastQuorum Pipeline

## Prerequisites

- macOS ARM64 (Apple Silicon)
- Pixi package manager (automatically installed if not present)

## Quick Start

1. **Clone and navigate to the pipeline directory:**

   ```bash
   cd pipelines/macos-arm64/fastquorum
   ```

2. **Run the pipeline:**
   ```bash
   ./run.sh
   ```

The `run.sh` script will:

- Install Pixi if not already installed
- Install all required dependencies
- Generate test data if not present
- Run the FastQuorum pipeline

## Pipeline Components

### Processes

1. **FASTQC_QC**: Performs quality control on FASTQ files
2. **SAMTOOLS_INDEX**: Indexes reference genomes
3. **BCFTOOLS_VARIANT_CALLING**: Performs variant calling
4. **GATK_ANALYSIS**: Runs GATK genomic analysis
5. **MULTIQC_REPORT**: Generates comprehensive reports

### Parameters

- `--input`: Input FASTQ files (default: `*.fastq`)
- `--outdir`: Output directory (default: `results`)
- `--iterations`: Number of iterations to run (default: `5`)
- `--threads`: Number of threads for parallel processing (default: `4`)

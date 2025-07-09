# FastQuorum Pipeline

## Prerequisites

- macOS Intel
- Pixi package manager (automatically installed if not present)

## Quick Start

1. **Clone and navigate to the pipeline directory:**

   ```bash
   cd pipelines/macos-intel-x86/fastquorum
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

### Parameters

- `--input`: Input FASTQ files (default: `*.fastq`)
- `--outdir`: Output directory (default: `results`)
- `--iterations`: Number of iterations to run (default: `5`)
- `--threads`: Number of threads for parallel processing (default: `4`)

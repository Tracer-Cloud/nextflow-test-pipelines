# Tracer WDL Pipeline (Linux x86 Ubuntu)

## Requirements

- Linux x86_64 system
- At least 2GB RAM and 1 vCPU
- [Pixi](https://pixi.sh/) (will be installed automatically if missing)

## Setup & Quick Start

1. **Run the pipeline:**
   ```bash
   ./run.sh
   ```
   This script will:
   - Install Pixi if not already present
   - Set up the environment
   - Run the WDL pipeline using MiniWDL

## Manual Usage

To run steps manually:

```bash
pixi run --manifest-path ../../shared/wdl/pixi.toml setup
pixi run --manifest-path ../../shared/wdl/pixi.toml pipeline
```

## Input Files

The pipeline expects the following input files in the `data/` directory:

- `sample_R1.fastq`
- `sample_R2.fastq`
- `genome.fa`
- `genes.gtf`
- `test.bam`

**Example data files** are available in `../../shared/wdl/data/`. You may need to copy or symlink them into your local `data/` directory, or adjust the input JSON accordingly.

## Troubleshooting

- If you see missing file errors, ensure all required input files are present in the `data/` directory.
- For dependency issues, re-run:
  ```bash
  pixi run --manifest-path ../../shared/wdl/pixi.toml setup
  ```
- For more verbose output, add `set -x` near the top of `run.sh`.

## References

- Workflow: `../../shared/wdl/tracer_wdl_minimal.wdl`
- Input template: `../../shared/wdl/tracer_wdl_minimal.inputs.json`

# Shared Nextflow Pipelines

This directory contains shared Nextflow workflows and configurations that can be used across different platforms and environments.

## Structure

```
shared/nextflow/
├── main.nf                 # Main pipeline entry point
├── configs/                # Configuration files
│   ├── basic.config        # Basic configuration for simple workflows
│   ├── conda.config        # Conda-specific configuration
│   └── pixi.config         # Pixi-specific configuration
├── workflows/              # Shared workflow modules
│   ├── tool-execution.nf   # Bioinformatics tool execution workflow
│   └── fasta-analysis.nf   # FASTA file analysis workflow
└── test_data/              # Test data files
```

## Usage

### Basic Version Check (Default)

```bash
nextflow run ../../shared/nextflow/main.nf -c ../../shared/nextflow/configs/basic.config
```

### FASTA Analysis with Conda

```bash
nextflow run ../../shared/nextflow/main.nf -c ../../shared/nextflow/configs/conda.config --workflow fasta_analysis
```

### FASTA Analysis with Pixi

```bash
nextflow run ../../shared/nextflow/main.nf -c ../../shared/nextflow/configs/pixi.config --workflow fasta_analysis
```

## Workflows

### Tool Execution Workflow

- Executes common bioinformatics tools (FastQC, STAR, Samtools) with real data
- Outputs results to `results/tool_outputs.txt`

### FASTA Analysis Workflow

- Analyzes FASTA files for sequence statistics
- Counts sequences in FASTA files
- Checks versions of STAR and Salmon
- Outputs results to `results/fasta_stats/` and `results/counts/`

## Configurations

### Basic Config

- Simple configuration for tool version checking
- Minimal resource requirements
- Ignores errors to continue execution

### Conda Config

- Configured for conda environments
- Includes conda environment specification
- Higher resource requirements for FASTA analysis

### Pixi Config

- Configured for Pixi dependency management
- No conda environment needed
- Comprehensive logging and reporting
- Multiple execution profiles (standard, debug, fast)

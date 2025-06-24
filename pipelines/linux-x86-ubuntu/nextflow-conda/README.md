# Nextflow Pipeline on Linux x86 using Conda

# Linux x86-64 Ubuntu Nextflow Pipeline - Conda Version

This directory contains a **Conda-based Nextflow pipeline** for traditional package management. Uses bash scripts and conda environments for tool installation.

## 🎯 **Three-Tier Pipeline System**

- **PIXI Pipeline** (`../nextflow-pixi`): Modern, fast package management
- **CONDA Pipeline** (this directory): Traditional conda-based setup
- **DOCKER Pipeline** (`../nextflow-docker-not-supported`): Full bioinformatics analysis with Docker

## 🚀 Quick Start - Conda Pipeline

### Prerequisites
- Linux x86-64 system
- sudo access for package installation

### One-Command Setup

1. **Run the setup script:**

   ```bash
   ./run.sh
   ```

2. **Activate conda in your current shell session:**

   ```bash
   source ~/.bashrc
   ```

   Or alternatively, use the helper script:

   ```bash
   source activate-conda.sh
   ```

3. **Verify conda is available:**
   ```bash
   conda --version
   ```

## Files

- `pixi.toml` - Pixi configuration with dependencies and tasks (recommended)
- `main.nf` - Nextflow pipeline definition (simple tool version checks)
- `nextflow.config` - Nextflow configuration
- `custom.config` - Custom configuration for nf-core pipelines
- `test_data/` - Sample test data for the pipeline
- `run.sh` - Alternative setup script that installs Java, Miniconda, and Nextflow
- `activate-conda.sh` - Helper script to activate conda in current shell session

## Troubleshooting

### Conda command not found after running run.sh

This is expected behavior. The `run.sh` script installs conda and configures it, but you need to activate it in your shell session:

**Option 1:** Source your bashrc file

```bash
source ~/.bashrc
```

**Option 2:** Use the activation helper script

```bash
source activate-conda.sh
```

**Option 3:** Restart your terminal/shell session

### Why does this happen?

The setup script modifies your `~/.bashrc` file to include conda in your PATH, but these changes only take effect in new shell sessions or when you explicitly source the bashrc file.

## Usage

### Pixi Tasks (Recommended)

```bash
# Check all available tasks
pixi task list

# Setup environment and directories
pixi run setup

# Check tool versions and environment
pixi run check-env

# Run the main pipeline
pixi run pipeline

# Run pipeline with custom output
pixi run pipeline-custom my_custom_results

# Run development workflow (clean + setup + check + test)
pixi run dev

# Run nf-core RNA-seq pipeline
pixi run nf-core-rnaseq

# Clean up all generated files
pixi run clean
```

### Pipeline Description

This directory contains a simple Nextflow pipeline that checks versions of common bioinformatics tools:

The pipeline will:

- Check versions of FastQC, STAR, Samtools, BWA, and GATK
- Create a `tool_versions.txt` file in the results directory
- Continue even if some tools are not available (uses `errorStrategy = 'ignore'`)
- Use 1GB memory per process step

### Manual Nextflow Execution

If you prefer to run nextflow directly (after `pixi install`):

```bash
# Run the local pipeline
nextflow run main.nf --outdir results

# Run nf-core rnaseq pipeline
nextflow run nf-core/rnaseq -c custom.config -profile docker,test --outdir results -resume
```

### Legacy Conda Usage

If using the bash setup instead of pixi:

```bash
conda --version
conda list
conda create -n myenv python=3.9
conda activate myenv
```

The `custom.config` file is included in this directory and contains:

- `process.errorStrategy = 'ignore'` - Allows the pipeline to continue even if some processes fail

## Why Pixi?

Pixi offers several advantages over traditional conda/bash setup:

- **Faster**: Parallel dependency resolution and installation
- **Reproducible**: Lock files ensure exact dependency versions
- **Isolated**: Each project has its own environment
- **Cross-platform**: Works consistently across Linux, macOS, and Windows
- **Task Management**: Built-in task runner for common workflows
- **No Activation**: Tools are automatically available when running tasks

## Dependencies

The pixi environment includes:

- **Nextflow** (>=25.4.4): Workflow management system
- **FastQC** (0.12.1): Quality control for sequencing data
- **STAR** (2.7.11b): RNA-seq aligner
- **Samtools** (1.21): SAM/BAM file manipulation
- **BWA** (0.7.18): DNA sequence aligner
- **GATK4** (4.6.1.0): Genome analysis toolkit
- **OpenJDK** (17.0.11): Java runtime for Nextflow and GATK

# Tracer Nextflow Pipelines for GitHub Codespaces

This directory contains bioinformatics pipeline configurations optimized for GitHub Codespaces environments to test Tracer.

<p align="center">
  <a href="https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=920248651&machine=largePremiumLinux"><img alt="Open in GitHub Codespaces" src="https://github.com/codespaces/badge.svg"></a>
</p>

## Supported Pipelines

### [fastquorum](./fastquorum/)

- **Description:** FastQuorum pipeline for Codespaces.
- **Quick Start:**
  ```bash
  ./fastquorum/run.sh
  ```
- **Specs:** Minimum 1 CPUs, 2GB RAM recommended.

### [wdl](./wdl/)

- **Description:** Runs a WDL pipeline using MiniWDL and Pixi. Handles setup, dependencies, and execution. See [README](./wdl/README.md) for details.
- **Quick Start:**
  ```bash
  ./wdl/run.sh
  ```
- **Specs:** Minimum 1 CPU, 2GB RAM recommended.

### [nextflow-conda](./nextflow-conda/)

- **Description:** Nextflow pipeline using Conda for dependency management. (README not provided; see pipeline scripts for details.)
- **Quick Start:**
  ```bash
  ./nextflow-conda/run.sh
  ```
- **Specs:** Minimum 1 CPUs, 1GB RAM.

### [nextflow-pixi](./nextflow-pixi/)

- **Description:** Nextflow pipeline using Pixi for dependency management. See [README](./nextflow-pixi/README.md) for details.
- **Quick Start:**
  ```bash
  cd pipelines/codespaces/nextflow-pixi
  ./run.sh
  ```
- **Specs:** Minimum 1 CPUs, 1GB RAM.

---

- For more details, see each pipeline's README or script.

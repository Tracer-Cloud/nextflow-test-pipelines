# Tracer Nextflow Pipelines for macOS arm64(Apple Silicon)

This directory contains bioinformatics pipeline configurations optimized for macOS arm64 environments to test Tracer.

## Supported Pipelines

### [fastquorum](./fastquorum/)

- **Description:** FastQuorum pipeline for Codespaces.
- **Quick Start:**
  ```bash
  cd fastquorum && ./run.sh
  ```
- **Specs:** Minimum 1 CPUs, 2GB RAM recommended.

### [nextflow-conda](./nextflow-conda/)

- **Description:** Nextflow pipeline using Conda for dependency management.
- **Quick Start:**
  ```bash
  cd nextflow-conda && ./run.sh
  ```
- **Specs:** Minimum 1 CPUs, 1GB RAM.

### [nextflow-pixi](./nextflow-pixi/)

- **Description:** Nextflow pipeline using Pixi for dependency management. See [README](./nextflow-pixi/README.md) for details.
- **Quick Start:**
  ```bash
  cd nextflow-pixi && ./run.sh
  ```
- **Specs:** Minimum 1 CPUs, 1GB RAM.

---

- For more details, see each pipeline's README or script.

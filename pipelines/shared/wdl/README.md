# Tracer WDL exmaple

1. Intall Java:

```bash
sudo apt-get update && sudo apt-get install default-jre -y
```

2. Install Cromwell:

```bash
wget https://github.com/broadinstitute/cromwell/releases/download/84/cromwell-84.jar -O cromwell.jar
```

```bash
# Verify installation
java -jar cromwell.jar --version
```

3. Run the workload

```bash
java -jar cromwell.jar run fastq_subsample.wdl --inputs ./fastq_subsample.inputs.json
```

# Other notes

WDL workflows for use on AnVIL and other platforms.

- `fastq_subsample`: subsets, or samples, a fastq.gz file. It currently takes a number of random reads to create a smaller file. This is intended for the purposes of educational activities, creating files for testing, etc. [Dockstore link](https://dockstore.org/workflows/github.com/fhdsl/AnVIL_WDLs/fastq_subsample).

# Create a simple fastqfile

````
# STAR + Samtools WDL Pipeline

This pipeline demonstrates a typical RNA-seq alignment and post-processing workflow using STAR and multiple samtools subcommands, all orchestrated via WDL.

## Prerequisites
- [miniwdl](https://github.com/chanzuckerberg/miniwdl) **or** [Cromwell](https://github.com/broadinstitute/cromwell)
- Docker (for running tasks in containers)
- Test data: `genome.fa`, `genes.gtf`, `reads_1.fastq.gz`, `reads_2.fastq.gz` (provided in this folder)

## How to Run

```bash
cd pipelines/shared/wdl
chmod +x run.sh
./run.sh
````

The script will automatically use `miniwdl` if available, otherwise `cromwell`.

## Workflow Steps

1. **samtools faidx**: Index the reference genome.
2. **STAR**: Align paired-end reads to the genome.
3. **samtools view**: Convert SAM to BAM.
4. **samtools sort**: Sort BAM file.
5. **samtools index**: Index the sorted BAM.
6. **samtools flagstat**: Alignment summary statistics.
7. **samtools idxstats**: Per-chromosome alignment stats.
8. **samtools stats**: Detailed alignment stats.
9. **samtools faidx (region extract)**: Extract a region from the reference genome.

## Outputs

- Sorted BAM and index
- Alignment statistics (flagstat, idxstats, stats)
- Extracted region FASTA

## Example Data

- `genome.fa`: Small reference genome
- `genes.gtf`: Example annotation
- `reads_1.fastq.gz`, `reads_2.fastq.gz`: Small paired-end reads

## Customization

- Edit `run.sh` to change input files or region.
- Edit `star_samtools_pipeline.wdl` to modify workflow steps.

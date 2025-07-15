#!/bin/bash
set -euo pipefail

# Change to script directory
cd "$(dirname "$0")"

# Create data directory if it doesn't exist
mkdir -p data

# URLs for small public test data
FASTA_URL="https://ftp.ensembl.org/pub/release-110/fasta/saccharomyces_cerevisiae/dna/Saccharomyces_cerevisiae.R64-1-1.dna.chromosome.I.fa.gz"
GTF_URL="https://ftp.ensembl.org/pub/release-110/gtf/saccharomyces_cerevisiae/Saccharomyces_cerevisiae.R64-1-1.110.gtf.gz"
FQ1_URL="https://ftp.sra.ebi.ac.uk/vol1/fastq/SRR014/SRR014849/SRR014849_1.fastq.gz"
FQ2_URL="https://ftp.sra.ebi.ac.uk/vol1/fastq/SRR014/SRR014849/SRR014849_2.fastq.gz"

# Download reference genome if missing
if [ ! -f data/genome.fa.gz ]; then
  echo "Downloading reference genome..."
  wget -O data/genome.fa.gz "$FASTA_URL" || curl -L "$FASTA_URL" -o data/genome.fa.gz
  gunzip -f data/genome.fa.gz
fi

# Download GTF if missing
if [ ! -f data/genes.gtf.gz ]; then
  echo "Downloading annotation GTF..."
  wget -O data/genes.gtf.gz "$GTF_URL" || curl -L "$GTF_URL" -o data/genes.gtf.gz
  gunzip -f data/genes.gtf.gz
fi

# Download FASTQ files if missing
if [ ! -f data/reads_1.fastq.gz ]; then
  echo "Downloading read 1 FASTQ..."
  wget -O data/reads_1.fastq.gz "$FQ1_URL" || curl -L "$FQ1_URL" -o data/reads_1.fastq.gz
fi
if [ ! -f data/reads_2.fastq.gz ]; then
  echo "Downloading read 2 FASTQ..."
  wget -O data/reads_2.fastq.gz "$FQ2_URL" || curl -L "$FQ2_URL" -o data/reads_2.fastq.gz
fi

# Update input JSON if needed (assume correct names for now)

# Run the pipeline
java -jar cromwell.jar run star_samtools_pipeline.wdl --inputs star_samtools_pipeline_inputs.json
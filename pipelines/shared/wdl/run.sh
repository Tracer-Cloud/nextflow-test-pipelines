#!/bin/bash
set -e

# ---
# Tracer WDL Minimal Pipeline Runner
#
# This script downloads a real RNA-seq dataset (paired-end FASTQ), a reference genome, and a GTF annotation file.
# It then runs the tracer_wdl_minimal.wdl pipeline using miniwdl via pixi.
# The pipeline performs:
#   - Quality control (FastQC)
#   - Alignment (STAR)
#   - BAM file indexing and stats (samtools)
#
# Data sources:
#   - RNA-seq: GIAB AshkenazimTrio (HG002_NA24385_son)
#   - Reference: GRCh38 chr22 (Ensembl)
#   - GTF: Ensembl chr22
# ---

# Set data directory
DATA_DIR="data"
mkdir -p "$DATA_DIR"

# RNA-seq data
FASTQ1="$DATA_DIR/NA24385_RNAseq_1.fastq.gz"
FASTQ2="$DATA_DIR/NA24385_RNAseq_2.fastq.gz"
if [ ! -f "$FASTQ1" ]; then
  echo "Downloading NA24385_RNAseq_1.fastq.gz (subset)..."
  curl -L --retry 3 --retry-delay 5 \
    "https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data_RNAseq/AshkenazimTrio/HG002_NA24385_son/NA24385_RNAseq_1.fastq.gz" \
    -o "$FASTQ1"
fi
if [ ! -f "$FASTQ2" ]; then
  echo "Downloading NA24385_RNAseq_2.fastq.gz (subset)..."
  curl -L --retry 3 --retry-delay 5 \
    "https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data_RNAseq/AshkenazimTrio/HG002_NA24385_son/NA24385_RNAseq_2.fastq.gz" \
    -o "$FASTQ2"
fi

# GRCh38 chr22 reference genome (Ensembl)
REF_FASTA="$DATA_DIR/chr22.fa"
if [ ! -f "$REF_FASTA" ]; then
  echo "Downloading GRCh38 chr22 reference..."
  curl -L --retry 3 --retry-delay 5 \
    "https://ftp.ensembl.org/pub/release-110/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.chromosome.22.fa.gz" \
    -o "$REF_FASTA.gz"
  gunzip -c "$REF_FASTA.gz" > "$REF_FASTA"
  rm "$REF_FASTA.gz"
fi

# GTF annotation for chr22 (Ensembl)
GTF="$DATA_DIR/chr22.gtf"
if [ ! -f "$GTF" ]; then
  echo "Downloading GRCh38 chr22 GTF annotation..."
  curl -L --retry 3 --retry-delay 5 \
    "https://ftp.ensembl.org/pub/release-110/gtf/homo_sapiens/Homo_sapiens.GRCh38.110.chr.gtf.gz" \
    -o "$DATA_DIR/chr.gtf.gz"
  gunzip -c "$DATA_DIR/chr.gtf.gz" | grep '^22\s' > "$GTF"
  rm "$DATA_DIR/chr.gtf.gz"
fi

# Index the reference genome for STAR (if not already indexed)
STAR_INDEX_DIR="$DATA_DIR/star_index"
if [ ! -d "$STAR_INDEX_DIR" ]; then
  echo "Generating STAR index for chr22..."
  pixi run STAR --runMode genomeGenerate --genomeDir "$STAR_INDEX_DIR" --genomeFastaFiles "$REF_FASTA" --sjdbGTFfile "$GTF" --runThreadN 2
fi

# Generate a test BAM file (for samtools tasks)
TEST_BAM="$DATA_DIR/test.bam"
if [ ! -f "$TEST_BAM" ]; then
  echo "Generating test BAM file..."
  pixi run samtools faidx "$REF_FASTA"
  REFNAME=$(head -1 "$REF_FASTA" | sed 's/>//')
  echo -e "@HD\tVN:1.0\tSO:unsorted\n@SQ\tSN:${REFNAME}\tLN:51304566\nread1\t0\t${REFNAME}\t1\t255\t10M\t*\t0\t0\tACGTACGTAC\t*" > "$DATA_DIR/minimal.sam"
  pixi run samtools view -bS "$DATA_DIR/minimal.sam" > "$TEST_BAM"
  rm "$DATA_DIR/minimal.sam"
fi

# Update tracer_wdl_minimal.inputs.json
cat > tracer_wdl_minimal.inputs.json <<EOF
{
  "tracer_wdl_minimal.fastq1": "$FASTQ1",
  "tracer_wdl_minimal.fastq2": "$FASTQ2",
  "tracer_wdl_minimal.reference_fasta": "$REF_FASTA",
  "tracer_wdl_minimal.gtf": "$GTF",
  "tracer_wdl_minimal.test_bam": "$TEST_BAM"
}
EOF

echo "\n---"
echo "Running Tracer WDL Minimal pipeline with miniwdl (real data)"
echo "  - FASTQ1: $FASTQ1"
echo "  - FASTQ2: $FASTQ2"
echo "  - Reference: $REF_FASTA"
echo "  - GTF: $GTF"
echo "  - Test BAM: $TEST_BAM"
echo "---\n"

pixi run pipeline

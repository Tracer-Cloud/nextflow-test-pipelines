#!/bin/bash
set -e

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

# Faster GTF download for chr22 only
GTF="$DATA_DIR/chr22.gtf"
if [ ! -f "$GTF" ]; then
  echo "Downloading GRCh38 chr22 GTF annotation"
  GTF_GZ="$DATA_DIR/chr.gtf.gz"
  curl -L --retry 3 --retry-delay 5 \
    "https://ftp.ensembl.org/pub/release-110/gtf/homo_sapiens/Homo_sapiens.GRCh38.110.chr.gtf.gz" \
    -o "$GTF_GZ"
  zgrep -P '^22\s' "$GTF_GZ" > "$GTF"
  rm "$GTF_GZ"
fi

# Index the reference genome for STAR (if not already indexed)
STAR_INDEX_DIR="$DATA_DIR/star_index"
if [ ! -d "$STAR_INDEX_DIR" ]; then
  echo "Generating STAR index for chr22..."
  pixi run STAR --runMode genomeGenerate --genomeDir "$STAR_INDEX_DIR" --genomeFastaFiles "$REF_FASTA" --sjdbGTFfile "$GTF" --runThreadN 2
fi

pixi run check

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

for f in chr22.fa chr22.gtf NA24385_RNAseq_1.fastq.gz NA24385_RNAseq_2.fastq.gz test.bam; do
  if [ -f "$f" ] && [ ! -f "$DATA_DIR/$f" ]; then
    mv "$f" "$DATA_DIR/"
  fi
  ln -sf "$DATA_DIR/$f" .
done

cat > tracer_wdl_minimal.inputs.json <<EOF
{
  "tracer_wdl_minimal.fastq1": "NA24385_RNAseq_1.fastq.gz",
  "tracer_wdl_minimal.fastq2": "NA24385_RNAseq_2.fastq.gz",
  "tracer_wdl_minimal.reference_fasta": "chr22.fa",
  "tracer_wdl_minimal.gtf": "chr22.gtf",
  "tracer_wdl_minimal.test_bam": "test.bam"
}
EOF

echo "Running Tracer WDL Minimal pipeline with miniwdl"
echo "  - FASTQ1: $FASTQ1"
echo "  - FASTQ2: $FASTQ2"
echo "  - Reference: $REF_FASTA"
echo "  - GTF: $GTF"
echo "  - Test BAM: $TEST_BAM"
echo "---\n"

pixi run pipeline

REQUIRED=("NA24385_RNAseq_1.fastq.gz" "NA24385_RNAseq_2.fastq.gz" "chr22.fa" "chr22.gtf" "test.bam")
for f in "${REQUIRED[@]}"; do
  if [ ! -s "$DATA_DIR/$f" ]; then
    echo "ERROR: Required file $DATA_DIR/$f is missing or empty!" >&2
    ls -lh "$DATA_DIR" >&2
    exit 1
  fi
  echo "Found $DATA_DIR/$f ($(ls -lh $DATA_DIR/$f | awk '{print $5}'))"
done

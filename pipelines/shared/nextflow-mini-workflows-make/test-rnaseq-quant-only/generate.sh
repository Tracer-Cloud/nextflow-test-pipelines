#!/bin/bash

set -e

# Ensure safe locale
export LC_ALL=C

# Generate 200 dummy transcripts (60bp each)
echo "Generating transcriptome.fa..."
> transcriptome.fa
for i in $(seq 1 200); do
    echo ">gene$i" >> transcriptome.fa
    cat /dev/urandom | LC_ALL=C tr -dc 'ACGT' | head -c 60 >> transcriptome.fa
    echo >> transcriptome.fa
done

# Normalize transcriptome formatting: make sure each >header has 1 sequence line
awk '
  /^>/ { if (seq) print seq; print; seq=""; next }
  { seq = seq $0 }
  END { if (seq) print seq }
' transcriptome.fa > fixed.fa && mv fixed.fa transcriptome.fa

# Generate 5,000 matching FASTQ reads from random transcripts
echo "Generating test_1.fastq.gz..."
mkdir -p data
> data/test_1.fastq

for i in $(seq 1 5000); do
    echo "@read$i" >> data/test_1.fastq
    grep -A1 '^>gene' transcriptome.fa | grep -v '^>' | shuf -n 1 >> data/test_1.fastq
    echo "+" >> data/test_1.fastq
    printf 'I%.0s' {1..60} >> data/test_1.fastq
    echo >> data/test_1.fastq
done

gzip -f data/test_1.fastq
echo "Done."
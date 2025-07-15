#!/bin/bash
set -e
mkdir -p reference data

# Create dummy genome
cat <<EOF > reference/genome.fa
>chr1
GATCTAGCTAGCTACGATCGATCGTACGTAGCTAGCTAGCATCGATCGATCGTAGCTAGCTA
EOF

# Create dummy GTF
cat <<EOF > reference/genes.gtf
chr1	source	gene	1	60	.	+	.	gene_id "gene1";
chr1	source	exon	1	60	.	+	.	gene_id "gene1"; exon_number "1";
EOF

# Create matching FASTQ
cat <<EOF | gzip > data/test_1.fastq.gz
@read1
GATCTAGCTAGCTACGATCGATCGTACGTAGCTAGCTAGCATCGATCGATCGTAGCTAGCTA
+
IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
EOF
#!/bin/bash
set -e

DATA_DIR="./data"
CROMWELL_JAR="./cromwell.jar"
WDL_FILE="./star_fastqc_samtools.wdl"
INPUTS_FILE="./inputs.json"
STAR_INDEX_DIR="$DATA_DIR/star_index"

mkdir -p $DATA_DIR

echo "Step 1: Generating tiny synthetic FASTQ files..."

cat <<EOF > $DATA_DIR/sample_R1.fastq
@SEQ_ID1
ACGTACGTACGTACGTACGT
+
FFFFFFFFFFFFFFFFFFFF
@SEQ_ID2
TGCATGCATGCATGCATGCA
+
FFFFFFFFFFFFFFFFFFFF
EOF

cat <<EOF > $DATA_DIR/sample_R2.fastq
@SEQ_ID1
TGCATGCATGCATGCATGCA
+
FFFFFFFFFFFFFFFFFFFF
@SEQ_ID2
ACGTACGTACGTACGTACGT
+
FFFFFFFFFFFFFFFFFFFF
EOF

echo "Step 2: Generating tiny toy reference genome..."

cat <<EOF > $DATA_DIR/reference.fasta
>chrTiny
ACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGT
EOF

echo "Step 3: Generating STAR index..."
mkdir -p $STAR_INDEX_DIR
STAR --runMode genomeGenerate \
     --genomeDir $STAR_INDEX_DIR \
     --genomeFastaFiles $DATA_DIR/reference.fasta \
     --runThreadN 1 \
     --genomeSAindexNbases 2

echo "Step 4: Creating STAR index tarball..."
tar -czf $DATA_DIR/star_index.tar.gz -C $STAR_INDEX_DIR .

echo "Step 5: Generating inputs.json..."
cat <<EOF > $INPUTS_FILE
{
    "RNASeqMultiQC.fastq1": "$DATA_DIR/sample_R1.fastq",
    "RNASeqMultiQC.fastq2": "$DATA_DIR/sample_R2.fastq",
    "RNASeqMultiQC.reference_index_tar": "$DATA_DIR/star_index.tar.gz"
}
EOF

echo "Step 6: Running WDL pipeline with Cromwell..."
java -jar $CROMWELL_JAR run $WDL_FILE --inputs $INPUTS_FILE

echo "✅ Pipeline execution complete with tiny synthetic data."
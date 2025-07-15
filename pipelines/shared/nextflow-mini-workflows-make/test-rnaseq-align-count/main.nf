#!/usr/bin/env nextflow

nextflow.enable.dsl=2

params.reads      = "data/*.fastq.gz"
params.genome_fa  = "reference/genome.fa"
params.annotation = "reference/genes.gtf"

workflow {
    ch_reads  = Channel.fromPath(params.reads)
    ch_genome = Channel.value(file(params.genome_fa))
    ch_gtf    = Channel.value(file(params.annotation))

    star_indexed = star_index(ch_genome, ch_gtf)
    aligned_bam  = star_align(ch_reads, star_indexed, ch_gtf)
    featurecounts(aligned_bam, ch_gtf)
}

process star_index {
    input:
    path genome
    path gtf

    output:
    path "star_index"

    script:
    """
    mkdir star_index
    STAR --runThreadN 2 --runMode genomeGenerate \
         --genomeDir star_index \
         --genomeFastaFiles $genome \
         --sjdbGTFfile $gtf \
         --sjdbOverhang 49
    """
}

process star_align {
    tag "$sample"
    input:
    path sample
    path index_dir
    path gtf

    output:
    path "Aligned.sortedByCoord.out.bam"

    script:
    """
    STAR --runThreadN 2 \
         --genomeDir $index_dir \
         --readFilesIn $sample \
         --readFilesCommand zcat \
         --sjdbGTFfile $gtf \
         --outSAMtype BAM SortedByCoordinate \
         --outFileNamePrefix ./
    """
}

process featurecounts {
    input:
    path bam
    path gtf

    output:
    path "counts.txt"

    script:
    """
    featureCounts -T 2 -a $gtf -o counts.txt $bam
    """
}
#!/usr/bin/env nextflow

nextflow.enable.dsl=2

params.reads = "data/*.fastq.gz"

workflow {
    Channel
        .fromPath(params.reads)
        .ifEmpty { error "No input FASTQ files found in: ${params.reads}" }
        .set { ch_reads }

    fastqc(ch_reads)
    trim_galore(ch_reads)
}

process fastqc {
    container 'biocontainers/fastqc:v0.11.9_cv8'

    tag "$sample"
    input:
    path sample

    output:
    path "fastqc"

    script:
    """
    mkdir -p fastqc
    fastqc $sample --outdir fastqc
    """
}

process trim_galore {
    container 'quay.io/biocontainers/trim-galore:0.6.10--hdfd78af_1'

    tag "$sample"
    input:
    path sample

    output:
    path "*_trimmed.fq.gz"

    script:
    """
    trim_galore --cores 1 --gzip $sample
    """
}

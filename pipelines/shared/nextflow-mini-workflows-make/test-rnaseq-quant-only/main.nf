#!/usr/bin/env nextflow

nextflow.enable.dsl=2

params.reads = "data/*.fastq.gz"
params.transcriptome = "transcriptome.fa"

workflow {
    ch_reads = Channel.fromPath(params.reads)
    ch_fasta = Channel.value(file(params.transcriptome))

    salmon_indexed = salmon_index(ch_fasta)
    salmon_quant(ch_reads, salmon_indexed)
}

process salmon_index {
    input:
    path fasta

    output:
    path "transcriptome_index"

    script:
    """
    salmon index -t $fasta -i transcriptome_index
    """
}


process salmon_quant {
    tag "$sample"
    input:
    path sample
    path index_dir

    output:
    path "quant.sf"

    script:
    """
    salmon quant -i $index_dir -l A -r $sample --minAssignedFrags 1 -o quants
    cp quants/quant.sf .
    """
}


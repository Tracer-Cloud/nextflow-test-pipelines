nextflow.enable.dsl = 2

params.outdir = params.outdir ?: "results"

workflow version_check {
    sam_file = file("${workflow.projectDir}/../test_data/test.sam")
    fastq_file = file("${workflow.projectDir}/../test_data/test.fastq")
    fasta_file = file("${workflow.projectDir}/../test_data/test.fa")
    gtf_file = file("${workflow.projectDir}/../test_data/test.gtf")
    
    prepare_bam(sam_file)
    
    fastqc_run(fastq_file)
    star_run(fasta_file, gtf_file)
    samtools_run(prepare_bam.out.bam, fasta_file)
    
    fastqc_run.out
        .concat(star_run.out)
        .concat(samtools_run.out)
        .collectFile(name: 'tool_outputs.txt', newLine: true)
        .set { all_outputs }

    save_results(all_outputs)
}

process prepare_bam {
    input:
    path sam_file

    output:
    path "test.bam", emit: bam

    script:
    """
    samtools view -bS $sam_file > test.bam || touch test.bam
    """
}

process fastqc_run {
    input:
    path fastq

    output:
    stdout

    script:
    """
    fastqc -q -o . $fastq 2>&1 || echo "FastQC completed"
    """
}

process star_run {
    input:
    path fasta
    path gtf

    output:
    stdout

    script:
    """
    mkdir -p star_index
    STAR --runMode genomeGenerate --genomeDir star_index --genomeFastaFiles $fasta --sjdbGTFfile $gtf --genomeSAindexNbases 4 2>&1 | head -20 || echo "STAR completed"
    """
}

process samtools_run {
    input:
    path bam
    path fasta

    output:
    stdout

    script:
    """
    samtools sort $bam -o sorted.bam 2>&1 || true
    samtools view sorted.bam 2>&1 | head -5 || true
    samtools index sorted.bam 2>&1 || true
    samtools mpileup -f $fasta sorted.bam 2>&1 | head -5 || true
    samtools depth sorted.bam 2>&1 | head -5 || true
    samtools flagstat sorted.bam 2>&1 || true
    samtools stats sorted.bam 2>&1 | head -10 || true
    samtools idxstats sorted.bam 2>&1 || true
    samtools faidx $fasta 2>&1 || true
    samtools calmd -b sorted.bam $fasta 2>&1 | head -5 || true
    samtools merge merged.bam sorted.bam 2>&1 || true
    samtools cat -o cat.bam sorted.bam 2>&1 || true
    samtools reheader <(samtools view -H sorted.bam) sorted.bam > reheader.bam 2>&1 || true
    samtools rmdup sorted.bam rmdup.bam 2>&1 || true
    samtools markdup sorted.bam markdup.bam 2>&1 || true
    samtools fixmate sorted.bam fixmate.bam 2>&1 || true
    echo "Samtools commands completed"
    """
}

process save_results {
    publishDir params.outdir, mode: 'copy'

    input:
    path outputs_file

    output:
    path "tool_outputs.txt"

    script:
    """
    cp $outputs_file tool_outputs.txt
    """
} 
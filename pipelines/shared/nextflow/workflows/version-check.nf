nextflow.enable.dsl = 2

params.outdir = params.outdir ?: "results"

workflow version_check {
    // Run simple version checks for various bioinformatics tools
    fastqc_version()
    star_version()
    samtools_version()

    // Collect all version outputs
    fastqc_version.out
        .concat(star_version.out)
        .concat(samtools_version.out)
        .collectFile(name: 'tool_versions.txt', newLine: true)
        .set { all_versions }

    // Save results
    save_results(all_versions)
}

process fastqc_version {
    output:
    stdout

    script:
    """
    echo "FastQC version:"
    fastqc --version || echo "FastQC not available"
    """
}

process star_version {
    output:
    stdout

    script:
    """
    echo "STAR version:"
    STAR align --runMode alignReads --version || echo "STAR not available"
    """
}

process samtools_version {
    output:
    stdout

    script:
    """
    echo "Samtools version:"
    samtools sort --version || echo "Samtools not available"
    samtools view --version || echo "Samtools not available"
    samtools index --version || echo "Samtools not available"
    samtools mpileup --version || echo "Samtools not available"
    samtools depth --version || echo "Samtools not available"
    samtools flagstat --version || echo "Samtools not available"
    samtools stats --version || echo "Samtools not available"
    samtools idxstats --version || echo "Samtools not available"
    samtools faidx --version || echo "Samtools not available"
    samtools calmd --version || echo "Samtools not available"
    samtools merge --version || echo "Samtools not available"
    samtools cat --version || echo "Samtools not available"
    samtools reheader --version || echo "Samtools not available"
    samtools rmdup --version || echo "Samtools not available"
    samtools markdup --version || echo "Samtools not available"
    samtools fixmate --version || echo "Samtools not available"
    samtools markdup --version || echo "Samtools not available"
    """
}

process save_results {
    publishDir params.outdir, mode: 'copy'

    input:
    path versions_file

    output:
    path "tool_versions.txt"

    script:
    """
    cp $versions_file tool_versions.txt.tmp
    """
} 
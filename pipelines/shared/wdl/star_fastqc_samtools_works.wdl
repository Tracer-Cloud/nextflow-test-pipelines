version 1.0

workflow RNASeqPipeline {
    input {
        File fastq1
        File fastq2
        File reference_genome
        File reference_index_tar
    }

    call STARAlign {
        input:
            fastq1 = fastq1,
            fastq2 = fastq2,
            reference_index_tar = reference_index_tar
    }

    call FastQC {
        input:
            fastq1 = fastq1,
            fastq2 = fastq2
    }

    call SamtoolsIndex {
        input:
            bam = STARAlign.aligned_bam
    }

    call SamtoolsFlagstat {
        input:
            bam = STARAlign.aligned_bam
    }

    call SamtoolsSort {
        input:
            bam = STARAlign.aligned_bam
    }

    call SamtoolsView {
        input:
            bam = STARAlign.aligned_bam
    }
}

task STARAlign {
    input {
        File fastq1
        File fastq2
        File reference_index_tar
    }

    command <<<
        if [ ! -f "Aligned.out.bam" ]; then
            mkdir -p genomeDir
            tar -xf ~{reference_index_tar} -C genomeDir
            STAR --genomeDir genomeDir --readFilesIn ~{fastq1} ~{fastq2} --runThreadN 4 --outFileNamePrefix .
        fi
    >>>

    output {
        File aligned_bam = "Aligned.out.bam"
    }

    runtime {
        cpu: 4
        memory: "8G"
    }
}

task FastQC {
    input {
        File fastq1
        File fastq2
    }

    command <<<
        if [ ! -d "fastqc_output1" ]; then
            mkdir fastqc_output1
            fastqc ~{fastq1} -o fastqc_output1
        fi
        if [ ! -d "fastqc_output2" ]; then
            mkdir fastqc_output2
            fastqc ~{fastq2} -o fastqc_output2
        fi
    >>>

    output {
        File fastqc1_html = "fastqc_output1/*.html"
        File fastqc2_html = "fastqc_output2/*.html"
    }

    runtime {
        cpu: 2
        memory: "4G"
    }
}

task SamtoolsIndex {
    input {
        File bam
    }

    command <<<
        if [ ! -f "~{bam}.bai" ]; then
            samtools index ~{bam}
        fi
    >>>

    output {
        File bam_index = "~{bam}.bai"
    }

    runtime {
        cpu: 1
        memory: "2G"
    }
}

task SamtoolsFlagstat {
    input {
        File bam
    }

    command <<<
        samtools flagstat ~{bam} > flagstat.txt
    >>>

    output {
        File flagstat = "flagstat.txt"
    }

    runtime {
        cpu: 1
        memory: "2G"
    }
}

task SamtoolsSort {
    input {
        File bam
    }

    command <<<
        samtools sort ~{bam} -o sorted.bam
    >>>

    output {
        File sorted_bam = "sorted.bam"
    }

    runtime {
        cpu: 2
        memory: "4G"
    }
}

task SamtoolsView {
    input {
        File bam
    }

    command <<<
        samtools view ~{bam} | head -n 10 > view_output.txt
    >>>

    output {
        File view_output = "view_output.txt"
    }

    runtime {
        cpu: 1
        memory: "2G"
    }
}

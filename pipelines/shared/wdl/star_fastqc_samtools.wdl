version 1.0

workflow RNASeqMultiQC {
  input {
    File fastq1
    File fastq2
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

  call MultiQC {
    input:
      qc_reports = FastQC.fastqc_html
  }

  output {
    File aligned_bam = STARAlign.aligned_bam
    Array[File] fastqc_html = FastQC.fastqc_html
    File multiqc_report = MultiQC.multiqc_report
  }
}

task STARAlign {
  input {
    File fastq1
    File fastq2
    File reference_index_tar
  }
  command <<<'
    set -euo pipefail
    mkdir -p genomeDir
    tar -xf ~{reference_index_tar} -C genomeDir
    STAR --genomeDir genomeDir --readFilesIn ~{fastq1} ~{fastq2} --runThreadN 1 --outFileNamePrefix .
    mv Aligned.out.bam aligned.bam
  >>>
  output {
    File aligned_bam = "aligned.bam"
  }
  runtime {
    cpu: 2
    memory: "4G"
  }
}

task FastQC {
  input {
    File fastq1
    File fastq2
  }
  command <<<'
    set -euo pipefail
    mkdir -p fastqc_output1 fastqc_output2
    fastqc ~{fastq1} -o fastqc_output1
    fastqc ~{fastq2} -o fastqc_output2
  >>>
  output {
    Array[File] fastqc_html = glob("fastqc_output*/*.html")
  }
  runtime {
    cpu: 1
    memory: "2G"
  }
}

task MultiQC {
  input {
    Array[File] qc_reports
  }
  command <<<'
    set -euo pipefail
    multiqc .
  >>>
  output {
    File multiqc_report = "multiqc_report.html"
  }
  runtime {
    cpu: 1
    memory: "2G"
  }
}

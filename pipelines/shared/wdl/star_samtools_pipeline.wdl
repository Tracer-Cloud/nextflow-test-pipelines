version 1.0

workflow star_fastqc_multiqc_workflow {

  input {
    File fastqgz_file_read_1
    File? fastqgz_file_read_2
    String sample_id
    File star_index_tarball  # STAR index pre-generated tarball
  }

  call star_align {
    input:
      fastqgz_file_read_1 = fastqgz_file_read_1,
      fastqgz_file_read_2 = fastqgz_file_read_2,
      sample_id = sample_id,
      star_index_tarball = star_index_tarball
  }

  call fastqc_reads {
    input:
      fastqgz_file_read_1 = fastqgz_file_read_1,
      fastqgz_file_read_2 = fastqgz_file_read_2
  }

  call multiqc_summary {
    input:
      qc_reports = fastqc_reads.qc_reports
  }

  output {
    File aligned_bam = star_align.aligned_bam
    Array[File] qc_reports = fastqc_reads.qc_reports
    File multiqc_report = multiqc_summary.multiqc_report
  }
}

task star_align {
  input {
    File fastqgz_file_read_1
    File? fastqgz_file_read_2
    String sample_id
    File star_index_tarball
  }

  command <<<
    mkdir star_index
    tar -xvf ~{star_index_tarball} -C star_index

    if [ -z "~{fastqgz_file_read_2}" ]; then
      STAR --runThreadN 4 \
           --genomeDir star_index \
           --readFilesIn ~{fastqgz_file_read_1} \
           --readFilesCommand zcat \
           --outFileNamePrefix ~{sample_id}_ \
           --outSAMtype BAM SortedByCoordinate
    else
      STAR --runThreadN 4 \
           --genomeDir star_index \
           --readFilesIn ~{fastqgz_file_read_1} ~{fastqgz_file_read_2} \
           --readFilesCommand zcat \
           --outFileNamePrefix ~{sample_id}_ \
           --outSAMtype BAM SortedByCoordinate
    fi
  >>>

  output {
    File aligned_bam = "~{sample_id}_Aligned.sortedByCoord.out.bam"
  }

  runtime {
    docker: "quay.io/biocontainers/star:2.7.9a--0"
    cpu: 4
    memory: "16 GB"
  }
}

task fastqc_reads {
  input {
    File fastqgz_file_read_1
    File? fastqgz_file_read_2
  }

  command <<<
    fastqc ~{fastqgz_file_read_1}
    if [ -n "~{fastqgz_file_read_2}" ]; then
      fastqc ~{fastqgz_file_read_2}
    fi
  >>>

  output {
    Array[File] qc_reports = glob("*.html")
  }

  runtime {
    docker: "quay.io/biocontainers/fastqc:0.11.9--0"
    cpu: 2
    memory: "4 GB"
  }
}

task multiqc_summary {
  input {
    Array[File] qc_reports
  }

  command <<<
    multiqc .
  >>>

  output {
    File multiqc_report = "multiqc_report.html"
  }

  runtime {
    docker: "quay.io/biocontainers/multiqc:1.9--pyh9f0ad1d_0"
    cpu: 2
    memory: "4 GB"
  }
}

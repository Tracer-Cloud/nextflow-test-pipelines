workflow tracer_wdl_minimal {
  input {
    File fastq1 = "data/NA24385_RNAseq_1.fastq.gz"
    File fastq2 = "data/NA24385_RNAseq_2.fastq.gz"
    File reference_fasta = "data/chr22.fa"
    File gtf = "data/chr22.gtf"
    File test_bam = "data/test.bam"
  }

  call FastQC {
    input: fastq=fastq1
  }

  call STARAlign {
    input:
      fastq1=fastq1,
      fastq2=fastq2,
      star_index_dir="data/star_index"
  }

  call SamtoolsIndex {
    input:
      bam=test_bam
  }

  call SamtoolsStats {
    input:
      bam=test_bam
  }

  call SamtoolsIdxstats {
    input:
      bam=test_bam
  }

  call SamtoolsFaidx {
    input:
      reference_fasta=reference_fasta
  }

  call SamtoolsCat {
    input:
      bam=test_bam
  }

  call SamtoolsMerge {
    input:
      bam1=test_bam,
      bam2=test_bam
  }

  output {
    File fastqc_stdout = FastQC.stdout
    File fastqc_stderr = FastQC.stderr
    File aligned_bam = STARAlign.bam
    File sorted_bam_bai = SamtoolsIndex.bai
    File stats_txt = SamtoolsStats.stats_txt
    File idxstats_txt = SamtoolsIdxstats.idxstats_txt
    File reference_fai = SamtoolsFaidx.fai
    File cat_bam = SamtoolsCat.cat_bam
    File merged_bam = SamtoolsMerge.merged_bam
  }
}

task FastQC {
  input {
    File fastq
  }
  command <<<'
    if [ ! -s "${fastq}" ]; then
      echo "Input FASTQ file '${fastq}' does not exist or is empty!" >&2
      echo "Input FASTQ file '${fastq}' does not exist or is empty!" > stderr.txt
      touch stdout.txt
      exit 0
    fi
    set +e
    fastqc ${fastq} > stdout.txt 2> stderr.txt
    status=$?
    if [ $status -ne 0 ]; then
      echo "FastQC failed with exit code $status" >> stderr.txt
    fi
    exit 0
  >>>
  output {
    File stdout = "stdout.txt"
    File stderr = "stderr.txt"
  }
  runtime {
    docker: "quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0"
    cpu: 1
    memory: "1G"
  }
}

task STARAlign {
  input {
    File fastq1
    File fastq2
    String star_index_dir
  }
  command <<<
    STAR --genomeDir ${star_index_dir} --readFilesIn ${fastq1} ${fastq2} --runThreadN 1 --outSAMtype BAM Unsorted --outFileNamePrefix star_
    mv star_Aligned.out.bam aligned.bam
  >>>
  output {
    File bam = "aligned.bam"
  }
  runtime {
    docker: "quay.io/biocontainers/star:2.7.10b--h9ee0642_0"
    cpu: 1
    memory: "2G"
  }
}

task SamtoolsIndex {
  input {
    File bam
  }
  command <<<
    samtools index ${bam}
  >>>
  output {
    File bai = "${bam}.bai"
  }
  runtime {
    docker: "quay.io/biocontainers/samtools:1.20--h50ea8bc_0"
    cpu: 1
    memory: "1G"
  }
}

task SamtoolsStats {
  input {
    File bam
  }
  command <<<
    samtools stats ${bam} > stats.txt
  >>>
  output {
    File stats_txt = "stats.txt"
  }
  runtime {
    docker: "quay.io/biocontainers/samtools:1.20--h50ea8bc_0"
    cpu: 1
    memory: "1G"
  }
}

task SamtoolsIdxstats {
  input {
    File bam
  }
  command <<<
    samtools idxstats ${bam} > idxstats.txt
  >>>
  output {
    File idxstats_txt = "idxstats.txt"
  }
  runtime {
    docker: "quay.io/biocontainers/samtools:1.20--h50ea8bc_0"
    cpu: 1
    memory: "1G"
  }
}

task SamtoolsFaidx {
  input {
    File reference_fasta
  }
  command <<<
    samtools faidx ${reference_fasta}
  >>>
  output {
    File fai = "${reference_fasta}.fai"
  }
  runtime {
    docker: "quay.io/biocontainers/samtools:1.20--h50ea8bc_0"
    cpu: 1
    memory: "1G"
  }
}

task SamtoolsCat {
  input {
    File bam
  }
  command <<<
    samtools cat ${bam} > cat.bam
  >>>
  output {
    File cat_bam = "cat.bam"
  }
  runtime {
    docker: "quay.io/biocontainers/samtools:1.20--h50ea8bc_0"
    cpu: 1
    memory: "1G"
  }
}

task SamtoolsMerge {
  input {
    File bam1
    File bam2
  }
  command <<<
    samtools merge merged.bam ${bam1} ${bam2}
  >>>
  output {
    File merged_bam = "merged.bam"
  }
  runtime {
    docker: "quay.io/biocontainers/samtools:1.20--h50ea8bc_0"
    cpu: 1
    memory: "1G"
  }
}
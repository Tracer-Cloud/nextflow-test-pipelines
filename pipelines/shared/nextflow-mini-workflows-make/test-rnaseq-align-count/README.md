
## 📄 `test-rnaseq-align-count` — Aligner-Based RNA-Seq Demo Pipeline

This is a small, fast-running **Nextflow pipeline** that demonstrates the use of alignment and quantification tools often found in RNA-seq workflows.

---

### ✅ Tools Used

| Step            | Tool          | Purpose                                  |
| --------------- | ------------- | ---------------------------------------- |
| `STAR` (index)  | STAR          | Builds genome index from `.fa` + `.gtf`  |
| `STAR` (align)  | STAR          | Aligns reads to genome using `zcat`      |
| `featureCounts` | Subread suite | Quantifies gene-level counts from `.bam` |

---

### 🧪 What It Does

* Generates a small synthetic genome and annotation
* Aligns a dummy FASTQ file to the reference using STAR
* Produces a sorted BAM file
* Runs `featureCounts` on the BAM to compute `counts.txt`

---

### 📁 Structure

```
test-rnaseq-align-count/
├── main.nf                  # Nextflow pipeline
├── generate.sh  # Script to create dummy genome, GTF, and FASTQ
├── reference/
│   ├── genome.fa
│   └── genes.gtf
└── data/
    └── test_1.fastq.gz
```

---

### ▶️ How to Run

```bash
cd test-rnaseq-align-count
# (Optional) Step 1: Generate reference and test data
./generate.sh

# Step 2: Run the Nextflow pipeline
nextflow run main.nf

# Step 3: Run Tracer 
tracer init --pipeline-name nf-mini-align-count --environment demo --pipeline-type rnaseq-align-coount --user-id vincent
```


---

### 🧭 Tracer Observability

This pipeline triggers observable activity from:

* `.fa`, `.gtf`, and `.fastq.gz` files
* `STAR` index and align commands
* `featureCounts` read from `.bam`


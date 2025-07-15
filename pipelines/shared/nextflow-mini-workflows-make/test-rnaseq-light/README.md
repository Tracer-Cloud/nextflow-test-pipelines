
## 📄 `test-rnaseq-light` — Lightweight RNA-Seq Test Pipeline

This is a **minimal Nextflow pipeline** that runs in under **2 minutes**, designed for:

* Fast testing with Tracer
* Local dev loop validation
* CI pipelines

---

### ✅ Tools Used

| Step           | Tool                                                                             | Notes                             |
| -------------- | -------------------------------------------------------------------------------- | --------------------------------- |
| **QC**         | [`fastqc`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)           | Runs quality control on raw FASTQ |
| **Trimming**   | [`trim_galore`](https://www.bioinformatics.babraham.ac.uk/projects/trim_galore/) | Adapter trimming using `cutadapt` |
| **Strandness** | [`infer_experiment.py`](http://rseqc.sourceforge.net/) (from `RSeQC`)            | Infers strandness using dummy BED |

---

### 📁 Project Structure

```
test-rnaseq-light/
├── main.nf           # The Nextflow pipeline
├── dummy.bed         # Minimal BED file for strand inference
└── data/
    └── test_1.fastq.gz  # Sample FASTQ file (1-read test case)
```

---

### ▶️ How to Run

```bash
cd test-rnaseq-light
nextflow run main.nf 
```

> Make sure tools like `fastqc`, `trim_galore`, and `infer_experiment.py` are in your `PATH`. You can also adapt this to run inside a Docker profile.

---

### 📦 Input Files

* Place `.fastq.gz` files in the `data/` folder.
* The pipeline reads from:

  ```bash
  data/*.fastq.gz
  ```

---

### 🧪 Output Summary

* `fastqc/` → HTML + QC stats
* `*_trimmed.fq.gz` → Trimmed FASTQ
* `strandness.txt` → Strand orientation summary

---

### 🧭 Tracer Tool Expectations

| Tool                  | Likely Tracer Label          |
| --------------------- | ---------------------------- |
| `fastqc`              | `fastqc`                     |
| `trim_galore`         | `trim_galore`, `cutadapt`    |
| `infer_experiment.py` | `infer_experiment` |

---



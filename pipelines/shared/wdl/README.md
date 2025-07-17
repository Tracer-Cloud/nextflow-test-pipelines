# Tracer WDL exmaple

1. Intall Java:

```bash
sudo apt-get update && sudo apt-get install default-jre -y
```

2. Install Cromwell:

```bash
wget https://github.com/broadinstitute/cromwell/releases/download/84/cromwell-84.jar -O cromwell.jar
```

```bash
# Verify installation
java -jar cromwell.jar --version
```

3. Run the workload

```bash
java -jar cromwell.jar run fastq_subsample.wdl --inputs ./fastq_subsample.inputs.json
```

# Other notes

WDL workflows for use on AnVIL and other platforms.

- `fastq_subsample`: subsets, or samples, a fastq.gz file. It currently takes a number of random reads to create a smaller file. This is intended for the purposes of educational activities, creating files for testing, etc. [Dockstore link](https://dockstore.org/workflows/github.com/fhdsl/AnVIL_WDLs/fastq_subsample).

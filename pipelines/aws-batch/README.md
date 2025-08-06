# Tracer AWS Batch Pipelines

This directory enables distributed, cloud-based testing of nf-core bioinformatics pipelines using [Nextflow](https://www.nextflow.io/) with [AWS Batch](https://aws.amazon.com/batch/).

## Folder Structure

- `pipelines/integrations-setup/aws-batch/`: Contains this Makefile and batch-specific test targets.
- `pipelines/nextflow/config`: Contains AWS Batch configuration (`batch.config`, GPU config, params).
- `pipelines/nextflow/*`: Cloned nf-core pipelines (e.g., `rnaseq`).

---

## Setup

To prepare the environment:

```bash
make setup_environment
````

This will:

* Download and bootstrap Spack.
* Install required CLI tools (Java, Nextflow, etc.).
* Prepare the runtime environment for Nextflow.

---

## Running Pipelines on AWS Batch

Each test target submits an nf-core pipeline to AWS Batch using `batch.config` profiles.

| Pipeline           | Target                                 | Description                         |
| ------------------ | -------------------------------------- | ----------------------------------- |
| RNA-seq            | `make test_rnaseq_aws_batch`           | Run RNA-seq pipeline (minimal test) |
| RNA-seq (full)     | `make test_full_rnaseq_aws_batch`      | Run extended RNA-seq test           |


---

## Execution Environments

### Option 1: Your AWS Account

1. Clone this repo and navigate to `integrations-setup/nextflow/aws-batch/`.
2. Ensure your AWS credentials are configured.
3. Run a test pipeline:

```bash
make test_rnaseq_aws_batch
```

Pipeline logs and metrics will appear in your Tracer observability dashboard (if enabled).

---

### Option 2: Tracer Sandbox (Preconfigured)

1. Launch the EC2 sandbox instance using the provided AMI and template.
2. SSH into the instance and switch context:

```bash
sudo su - ubuntu
cd nextflow-test-pipelines
```

3. Initialize the pipeline:

```bash
tracer init --pipeline-name aws_batch_test \
  --environment sandbox \
  --user-id vincent \
  --pipeline-type aws_batch_rnaseq
```

4. Execute the test:

```bash
make test_rnaseq_aws_batch
```

---

## CloudFormation Deployment

To update the AWS Batch compute environment via CloudFormation:

### Validate the Template

```bash
aws cloudformation validate-template \
  --template-body file://nextflow-batch-resources.yml
```

### Deploy the Template

```bash
aws cloudformation deploy \
  --template-file ./cloudformation/nextflow-batch-resources.yml \
  --stack-name nextflow-batch-resources \
  --capabilities CAPABILITY_NAMED_IAM
```

This will provision IAM roles, job queues, and compute environments needed for Nextflow pipelines on AWS Batch.

----

# Tracer: RNA-seq Pipeline on AWS Batch

This directory contains the infrastructure setup and configuration files to run the [nf-core RNA-seq pipeline](https://nf-co.re/rnaseq/3.20.0) on AWS Batch using Nextflow.

## Prerequisites

- AWS CLI v2 installed and configured
- Terraform installed (for infrastructure setup)
- Nextflow installed
- Docker installed (for local testing)

## Tracer AWS Account Users

If you have access to the Tracer AWS account, you can run the pipeline directly without setting up infrastructure:

```bash
./run.sh tracer run
```

This command uses the shared batch configuration and Tracer's pre-configured AWS resources. No setup or cleanup is needed.

## Quick Start

1. **Setup Infrastructure:**

   ```bash
   ./run.sh setup
   ```

2. **Run RNA-seq Pipeline:**

   ```bash
   ./run.sh run
   ```

   Or use the Tracer configuration:

   ```bash
   ./run.sh tracer run
   ```

3. **Cleanup Infrastructure:**
   ```bash
   ./run.sh cleanup
   ```

## Available Commands

- `./run.sh setup` - Setup AWS infrastructure (VPC, S3, Batch, etc.)
- `./run.sh run` - Run the RNA-seq pipeline with local config
- `./run.sh tracer run` - Run the RNA-seq pipeline with shared batch config
- `./run.sh cleanup` - Destroy AWS infrastructure
- `./run.sh status` - Show infrastructure status
- `./run.sh config` - Show current configuration
- `./run.sh refresh` - Refresh infrastructure variables from Terraform
- `./run.sh debug` - Debug AWS Batch infrastructure
- `./run.sh validate` - Validate infrastructure without running pipeline
- `./run.sh help` - Show help message

## Infrastructure Components

- VPC with public and private subnets
- AWS Batch compute environment with optimal instance types
- S3 buckets for work directory and outputs
- IAM roles and policies
- Security groups
- EC2 Instance Connect endpoint for debugging

## Configuration

The default configuration uses:

- **Region**: us-east-1 (you can change this in `terraform/variables.tf`)
- **Instance Types**: Optimized for CPU-intensive workloads
- **Max vCPUs**: 1024
- **Work Directory**: S3 bucket with format `{WORK_BUCKET_NAME}-{BUCKET_SUFFIX or auto-generated hash}`
- **Outputs Directory**: S3 bucket with format `{OUTPUTS_BUCKET_NAME}-{BUCKET_SUFFIX or auto-generated hash}`
- **Queue Name**: `tracer-{ENVIRONMENT_NAME}-queue`

### Customizing the Setup

You can customize bucket names and other settings using environment variables:

```bash
export WORK_BUCKET_NAME=my-custom-work-bucket
export OUTPUTS_BUCKET_NAME=my-custom-outputs-bucket
export ENVIRONMENT_NAME=my-environment
export BUCKET_SUFFIX=my-suffix
export CREATE_INSTANCE_CONNECT_ENDPOINT=false

./run.sh setup
```

Or set them inline for a single run:

```bash
WORK_BUCKET_NAME=my-work OUTPUTS_BUCKET_NAME=my-outputs BUCKET_SUFFIX=test123 ./run.sh setup
```

**Important notes**:

- Set `CREATE_INSTANCE_CONNECT_ENDPOINT=false` if you hit quota limits for EC2 Instance Connect Endpoints
- If S3 buckets already exist, Terraform will manage them. Set `force_destroy = true` in the Terraform config to allow cleanup

## Pipeline Configuration

The pipeline uses the shared batch configuration from `pipelines/shared/nextflow/config/batch.config` with RNA-seq specific settings:

- **Genome**: GRCh38
- **Protocol**: stranded
- **Aligner**: STAR + Salmon
- **Profile**: test (uses minimal test data)

## Monitoring and Outputs

The pipeline generates several types of outputs for monitoring and analysis:

- CloudWatch logs and metrics for AWS infrastructure
- Nextflow trace, report, timeline, and DAG files
- AWS Batch job monitoring through the AWS console
- Tracer integration for pipeline tracking

## File Structure

```
rnaseq/
├── config/
│   ├── batch.config          # Nextflow configuration
│   └── rnaseq-params.json   # Pipeline parameters
├── terraform/
│   ├── main.tf              # Infrastructure definition
│   ├── variables.tf         # Variable definitions
│   ├── outputs.tf           # Output values
│   ├── versions.tf          # Terraform versions
│   └── user_data_mime.sh    # EC2 instance setup script
├── .env.tracer              # Tracer AWS account configuration template
├── run.sh                   # Main runner script
└── README.md               # This file
```

## Troubleshooting

Common issues and solutions:

1. **"Infrastructure not found" error**: Make sure you've run `./run.sh setup` first to create the AWS resources
2. **AWS credentials error**: Run `aws configure` to set up your AWS credentials, or use `./run.sh tracer run` if you have access to the Tracer AWS account
3. **Terraform errors**: Check the terraform directory and run `terraform init` if needed
4. **Pipeline fails**: Check the Nextflow logs (`.nextflow.log`) and AWS Batch job status in the AWS console
5. **Batch queue issues**: Use `./run.sh debug` to inspect the AWS Batch infrastructure
6. **S3 bucket access issues**: Verify your AWS credentials have the necessary S3 permissions
7. **Environment variables not loading**: Make sure you have a `.env` file or use `./run.sh tracer run` for Tracer account

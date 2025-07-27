# GCP Batch Setup via Terraform + Cloud Scheduler

This setup uses Terraform to configure:
- A Cloud Scheduler cron job that submits GCP Batch jobs
- GCS buckets for Nextflow work and outputs
- Service accounts with required IAM roles

## 🚀 Prerequisites
- [Terraform](https://developer.hashicorp.com/terraform/downloads) installed
- [gcloud CLI](https://cloud.google.com/sdk/docs/install) installed and authenticated

## 🔧 Setup Instructions

### 1. Authenticate with Google Cloud
```bash
gcloud auth login
gcloud auth application-default login
```

### 2. Set Your Active Project
```bash
gcloud config set project YOUR_PROJECT_ID
```
Or verify your current project:
```bash
gcloud config get-value project
```
To list available projects:
```bash
gcloud projects list
```

### 3. Enable Required APIs
```bash
gcloud services enable \
  batch.googleapis.com \
  compute.googleapis.com \
  logging.googleapis.com \
  cloudscheduler.googleapis.com
```

### 4. Define Your Terraform Variables
Create a `terraform.tfvars` file:
```hcl
project_id              = "your-gcp-project-id"
region                  = "us-central1"
container_image_uri     = "ubuntu"  # Or your pipeline image
command                 = "echo Hello from GCP Batch"
scheduler_cron_schedule = "*/10 * * * *"
time_zone               = "UTC"
```

### 5. Initialize and Deploy with Terraform
```bash
terraform init
terraform apply
```
Approve the plan when prompted with `yes`.

### 6. Monitor Jobs
- Visit **Cloud Scheduler** in the GCP console to see scheduled executions
- Visit **GCP Batch** to see job details and logs
- Check **Cloud Logging** for runtime output

## ✅ Outputs
- Two GCS buckets (`tracer-nxf-work`, `tracer-nxf-outputs`)
- Cloud Scheduler job that triggers your batch container
- Service accounts with roles pre-configured for execution

## 📌 Notes
- Tracer variables can be injected via the `tracer_env_vars` map in `variables.tf`
- Adjust `command` and `container_image_uri` to run Nextflow or Fastquorum pipelines
---


## ✅ Verify That the Cron Job Creates a Batch Job

Verify that the `batch-job-invoker` cron job is correctly creating GCP Batch jobs.

### Option 1: Wait for the scheduled time
Let the cron job trigger automatically based on the schedule in `terraform.tfvars`.

### Option 2: Trigger manually via gcloud
```bash
gcloud scheduler jobs run batch-job-invoker --location=us-central1
```

### View Created Batch Jobs
```bash
gcloud batch jobs list \
  --filter="labels.source=terraform_cloud_scheduler" \
  --sort-by=~createTime
```

- The `--filter` flag limits the list to only include jobs created by this Terraform setup.
- The `--sort-by ~createTime` flag shows the most recent jobs first.

Visit [https://console.cloud.google.com/batch](https://console.cloud.google.com/batch) to inspect job logs, outputs, and runtime diagnostics.

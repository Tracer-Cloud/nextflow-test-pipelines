provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "tracer_batch_sa" {
  account_id   = "tracer-batch-sa"
  display_name = "Service Account for GCP Batch jobs"
  project      = var.project_id
}

resource "google_service_account" "tracer_scheduler_sa" {
  account_id   = "tracer-scheduler-sa"
  display_name = "Service Account for Cloud Scheduler"
  project      = var.project_id
}

resource "google_project_iam_member" "batch_sa_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.tracer_batch_sa.email}"
}

resource "google_project_iam_member" "batch_sa_agent" {
  project = var.project_id
  role    = "roles/batch.agentReporter"
  member  = "serviceAccount:${google_service_account.tracer_batch_sa.email}"
}

resource "google_project_iam_member" "scheduler_sa_batch" {
  project = var.project_id
  role    = "roles/batch.jobsEditor"
  member  = "serviceAccount:${google_service_account.tracer_scheduler_sa.email}"
}

resource "google_project_iam_member" "scheduler_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.tracer_scheduler_sa.email}"
}

resource "google_storage_bucket" "nxf_work" {
  name                        = "tracer-nxf-work"
  location                    = var.region
  uniform_bucket_level_access = true
  project                     = var.project_id

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30
    }
  }
}

resource "google_storage_bucket" "nxf_outputs" {
  name                        = "tracer-nxf-outputs"
  location                    = var.region
  uniform_bucket_level_access = true
  project                     = var.project_id
}

resource "google_cloud_scheduler_job" "trigger_batch" {
  name             = "batch-job-invoker"
  project          = var.project_id
  region           = var.region
  schedule         = var.scheduler_cron_schedule
  time_zone        = var.time_zone
  attempt_deadline = "180s"

  retry_config {
    max_doublings        = 5
    max_retry_duration   = "0s"
    max_backoff_duration = "3600s"
    min_backoff_duration = "5s"
  }

  http_target {
    http_method = "POST"
    uri         = "https://batch.googleapis.com/v1/projects/${var.project_id}/locations/${var.region}/jobs"
    headers = {
      "Content-Type" = "application/json"
      "User-Agent"   = "Google-Cloud-Scheduler"
    }
    body = base64encode(jsonencode({
      taskGroups = [{
        taskSpec = {
          runnables = [{
            container = {
              imageUri   = var.container_image_uri
              entrypoint = "bash"
              commands   = ["-c", var.command]
            }
          }],
          environment = {
            variables = var.tracer_env_vars
          }
        }
        taskCount = 1
      }],
      allocationPolicy = {
        serviceAccount = {
          email = google_service_account.tracer_batch_sa.email
        }
      },
      logsPolicy = {
        destination = "CLOUD_LOGGING"
      },
      labels = {
        source = "terraform_cloud_scheduler"
      }
    }))

    oauth_token {
      service_account_email = google_service_account.tracer_scheduler_sa.email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }
  }
}

variable "project_id" {}
variable "region" { default = "us-central1" }
variable "container_image_uri" { default = "ubuntu" }
variable "command" { default = "echo Hello from GCP Batch" }
variable "scheduler_cron_schedule" { default = "*/5 * * * *" }
variable "time_zone" { default = "UTC" }
variable "tracer_env_vars" {
  type = map(string)
  default = {
    TRACER_TRACE_ID      = "debug-123"
    TRACER_ENVIRONMENT   = "gcp_batch"
    TRACER_PIPELINE_NAME = "fastquorum"
    TRACER_OUTPUT_BUCKET = "tracer-nxf-outputs"
    TRACER_WORK_BUCKET   = "tracer-nxf-work"
  }
}

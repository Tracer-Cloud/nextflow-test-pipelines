provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "batch_sa" {
  account_id   = "batch-sa"
  display_name = "Batch Job Service Account"
}

resource "google_service_account" "scheduler_sa" {
  account_id   = "scheduler-sa"
  display_name = "Scheduler Trigger Service Account"
}

# === IAM Bindings for batch-sa ===
resource "google_project_iam_member" "batch_sa_logging" {
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.batch_sa.email}"
  project = var.project_id
}

resource "google_project_iam_member" "batch_sa_reporter" {
  role    = "roles/batch.agentReporter"
  member  = "serviceAccount:${google_service_account.batch_sa.email}"
  project = var.project_id
}

# === IAM Bindings for scheduler-sa ===
resource "google_project_iam_member" "scheduler_sa_editor" {
  role    = "roles/batch.jobsEditor"
  member  = "serviceAccount:${google_service_account.scheduler_sa.email}"
  project = var.project_id
}

resource "google_project_iam_member" "scheduler_sa_user" {
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.scheduler_sa.email}"
  project = var.project_id
}

# 🔐 Let scheduler-sa impersonate batch-sa directly (correct form)
resource "google_service_account_iam_member" "scheduler_impersonates_batch" {
  service_account_id = google_service_account.batch_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.scheduler_sa.email}"
}

# === Cloud Scheduler Job that triggers Batch ===
resource "google_cloud_scheduler_job" "trigger_batch" {
  name             = "batch-job-invoker"
  project          = var.project_id
  region           = var.region
  schedule         = var.scheduler_cron_schedule
  time_zone        = var.time_zone
  attempt_deadline = "180s"

  http_target {
    http_method = "POST"
    uri         = "https://batch.googleapis.com/v1/projects/${var.project_id}/locations/${var.region}/jobs"
    headers = {
      "Content-Type" = "application/json"
    }

    body = base64encode(jsonencode({
      taskGroups = [{
        taskSpec = {
          runnables = [{
            script = {
              path = "/usr/local/bin/tracer-bootstrap.sh"
            }
          }],
          environment = {
            variables = var.tracer_env_vars
          }
        },
        taskCount = 1
      }],
      allocationPolicy = {
        instances = [{
          policy = {
            provisioningModel = "STANDARD",
            machineType       = "e2-standard-2",
            bootDisk = {
              image = "projects/${var.project_id}/global/images/${var.custom_image_name}"
              # Optionally set disk size if needed
              # boot_disk_size_gb = 60
            }
          }
        }],
        serviceAccount = {
          email = google_service_account.batch_sa.email
        }
      },
      logsPolicy = {
        destination = "CLOUD_LOGGING"
      },
      labels = {
        source = "custom_image_test"
      }
    }))

    oauth_token {
      service_account_email = google_service_account.scheduler_sa.email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }
  }
}

# === Variables ===
variable "project_id" {}
variable "region" { default = "us-central1" }
variable "container_image_uri" { default = "ubuntu" }
variable "command" { default = "echo Hello from GCP Batch" }
variable "time_zone" { default = "UTC" }
variable "scheduler_cron_schedule" { default = "*/3 * * * *" }

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

variable "custom_image_name" {
  default = "tracer-base-image"
}

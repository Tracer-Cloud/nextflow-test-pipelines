provider "google" {
  project = var.project_id
  region  = var.region
}
data "google_project" "project" {
  project_id = var.project_id
}


resource "google_service_account" "scheduler" {
  account_id   = "scheduler-sa"
  display_name = "Scheduler SA"
}

resource "google_service_account" "batch" {
  account_id   = "batch-sa"
  display_name = "Batch SA"
}

resource "google_project_iam_member" "sa_batcheditor" {
  role    = "roles/batch.jobsEditor"
  member  = "serviceAccount:${google_service_account.scheduler.email}"
  project = var.project_id
}

resource "google_project_iam_member" "sa_serviceaccountuser" {
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.scheduler.email}"
  project = var.project_id
}

resource "google_service_account_iam_member" "cloudscheduler_impersonate" {
  service_account_id = google_service_account.scheduler.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudscheduler.iam.gserviceaccount.com"
}

resource "google_cloud_scheduler_job" "trigger_batch" {
  name      = "invoke-gcp-batch"
  project   = var.project_id
  region    = var.region
  schedule  = "*/5 * * * *"
  time_zone = "Africa/Lagos"
  depends_on = [
    google_service_account_iam_member.cloudscheduler_impersonate,
    google_project_iam_member.sa_serviceaccountuser,
    google_project_iam_member.sa_batcheditor
  ]

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
          runnables = [{ script = { text = "echo Hello from Terraform Scheduler" } }]
        }
        taskCount = 1
      }],
      allocationPolicy = {
        instances = [{
          policy = {
            provisioningModel = "STANDARD"
            bootDisk = {
              type   = "pd-balanced"
              sizeGb = 100
            }
          }
        }],
        serviceAccount = {
          email = google_service_account.batch.email
        }
      },
      logsPolicy = {
        destination = "CLOUD_LOGGING"
      },
      labels = {
        source = "terraform_and_cloud_scheduler_tutorial"
      }
    }))

    oauth_token {
      service_account_email = google_service_account.scheduler.email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }
  }
}


variable "project_id" {}
variable "region" { default = "us-central1" }
variable "container_image_uri" { default = "ubuntu" }
variable "command" { default = "echo Hello from GCP Batch" }
variable "scheduler_cron_schedule" { default = "*/3 * * * *" }
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


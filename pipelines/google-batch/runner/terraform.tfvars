# project_id = "testing-tracer"
project_id = "tracer-batch-test"
region     = "us-central1"
# custom_image_name       = "tracer-base-image"
scheduler_cron_schedule = "*/3 * * * *"
time_zone               = "Africa/Lagos"

tracer_env_vars = {
  TRACER_TRACE_ID      = "debug-123"
  TRACER_ENVIRONMENT   = "gcp_batch"
  TRACER_PIPELINE_NAME = "fastquorxum"
  TRACER_OUTPUT_BUCKET = "tracer-nxf-outputs"
  TRACER_WORK_BUCKET   = "tracer-nxf-work"
}

project_id              = "testing-tracer"
region                  = "us-central1"
custom_image_name       = "tracer-base-image"
scheduler_cron_schedule = "*/3 * * * *"
time_zone               = "UTC"

tracer_env_vars = {
  TRACER_TRACE_ID      = "debug-123"
  TRACER_ENVIRONMENT   = "gcp_batch"
  TRACER_PIPELINE_NAME = "fastquorum"
  TRACER_OUTPUT_BUCKET = "tracer-nxf-outputs"
  TRACER_WORK_BUCKET   = "tracer-nxf-work"
}

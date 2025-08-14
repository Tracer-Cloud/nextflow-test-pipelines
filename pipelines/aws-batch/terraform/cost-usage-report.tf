terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.72"
    }
  }
}

# -----------------------
# Variables (match CFN Parameters)
# -----------------------
variable "region"                     { type = string  default = "us-east-1" }
variable "cur_bucket_name"            { type = string  default = "tracer-nf-batch-cur" }
variable "cur_data_export_name"       { type = string  default = "NfBatchCUR" }
variable "report_prefix"              { type = string  default = "reports" }
variable "glue_database_name"         { type = string  default = "nf_batch_cost_analysis" }
variable "cur_workgroup_query_prefix" { type = string  default = "queries" }
variable "glue_crawler_role_name"     { type = string  default = "AWSGlueServiceRole-NfBatchCUR" }
variable "crawler_name"               { type = string  default = "NfBatchCURCrawler" }
variable "athena_workgroup_name"      { type = string  default = "NfBatchCUR" }

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

# -----------------------
# S3 bucket for CUR delivery
# -----------------------
resource "aws_s3_bucket" "cur" {
  bucket        = var.cur_bucket_name
  force_destroy = false

  lifecycle {
    # Mimic CFN Retain behavior (optional—remove if you prefer easy destroys)
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_ownership_controls" "cur" {
  bucket = aws_s3_bucket.cur.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "cur" {
  bucket                  = aws_s3_bucket.cur.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Allow Data Exports & legacy CUR to write
resource "aws_s3_bucket_policy" "cur" {
  bucket = aws_s3_bucket.cur.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "EnableAWSDataExportsToWriteToS3AndCheckPolicy",
        Effect    = "Allow",
        Principal = { Service = ["billingreports.amazonaws.com", "bcm-data-exports.amazonaws.com"] },
        Action    = ["s3:PutObject", "s3:GetBucketPolicy", "s3:GetBucketAcl"],
        Resource  = [
          "arn:aws:s3:::${aws_s3_bucket.cur.id}",
          "arn:aws:s3:::${aws_s3_bucket.cur.id}/*"
        ],
        Condition = {
          StringLike = {
            "aws:SourceArn" = [
              "arn:aws:cur:us-east-1:${data.aws_caller_identity.current.account_id}:definition/*",
              "arn:aws:bcm-data-exports:us-east-1:${data.aws_caller_identity.current.account_id}:export/*"
            ],
            "aws:SourceAccount" = "${data.aws_caller_identity.current.account_id}"
          }
        }
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_ownership_controls.cur,
    aws_s3_bucket_public_access_block.cur
  ]
}

# -----------------------
# BCM Data Exports - CUR 2.0 export
# -----------------------
resource "aws_bcmdataexports_export" "cur2" {
  depends_on = [aws_s3_bucket_policy.cur]

  export {
    name = var.cur_data_export_name

    data_query {
      # Table configuration for CUR 2.0
      table_configurations = {
        COST_AND_USAGE_REPORT = {
          INCLUDE_RESOURCES                  = "TRUE"
          INCLUDE_SPLIT_COST_ALLOCATION_DATA = "TRUE"
          TIME_GRANULARITY                   = "HOURLY"
        }
      }

      query_statement = <<-SQL
        SELECT bill_bill_type, bill_billing_entity, bill_billing_period_end_date, bill_billing_period_start_date, bill_invoice_id, bill_invoicing_entity, bill_payer_account_id, bill_payer_account_name, cost_category, discount, discount_bundled_discount, discount_total_discount, identity_line_item_id, identity_time_interval, line_item_availability_zone, line_item_blended_cost, line_item_blended_rate, line_item_currency_code, line_item_legal_entity, line_item_line_item_description, line_item_line_item_type, line_item_net_unblended_cost, line_item_net_unblended_rate, line_item_normalization_factor, line_item_normalized_usage_amount, line_item_operation, line_item_product_code, line_item_resource_id, line_item_tax_type, line_item_unblended_cost, line_item_unblended_rate, line_item_usage_account_id, line_item_usage_account_name, line_item_usage_amount, line_item_usage_end_date, line_item_usage_start_date, line_item_usage_type, pricing_currency, pricing_lease_contract_length, pricing_offering_class, pricing_public_on_demand_cost, pricing_public_on_demand_rate, pricing_purchase_option, pricing_rate_code, pricing_rate_id, pricing_term, pricing_unit, product, product_comment, product_fee_code, product_fee_description, product_from_location, product_from_location_type, product_from_region_code, product_instance_family, product_instance_type, product_instancesku, product_location, product_location_type, product_operation, product_pricing_unit, product_product_family, product_region_code, product_servicecode, product_sku, product_to_location, product_to_location_type, product_to_region_code, product_usagetype, reservation_amortized_upfront_cost_for_usage, reservation_amortized_upfront_fee_for_billing_period, reservation_availability_zone, reservation_effective_cost, reservation_end_time, reservation_modification_status, reservation_net_amortized_upfront_cost_for_usage, reservation_net_amortized_upfront_fee_for_billing_period, reservation_net_effective_cost, reservation_net_recurring_fee_for_usage, reservation_net_unused_amortized_upfront_fee_for_billing_period, reservation_net_unused_recurring_fee, reservation_net_upfront_value, reservation_normalized_units_per_reservation, reservation_number_of_reservations, reservation_recurring_fee_for_usage, reservation_reservation_a_r_n, reservation_start_time, reservation_subscription_id, reservation_total_reserved_normalized_units, reservation_total_reserved_units, reservation_units_per_reservation, reservation_unused_amortized_upfront_fee_for_billing_period, reservation_unused_normalized_unit_quantity, reservation_unused_quantity, reservation_unused_recurring_fee, reservation_upfront_value, resource_tags, savings_plan_amortized_upfront_commitment_for_billing_period, savings_plan_end_time, savings_plan_instance_type_family, savings_plan_net_amortized_upfront_commitment_for_billing_period, savings_plan_net_recurring_commitment_for_billing_period, savings_plan_net_savings_plan_effective_cost, savings_plan_offering_type, savings_plan_payment_option, savings_plan_purchase_term, savings_plan_recurring_commitment_for_billing_period, savings_plan_region, savings_plan_savings_plan_a_r_n, savings_plan_savings_plan_effective_cost, savings_plan_savings_plan_rate, savings_plan_start_time, savings_plan_total_commitment_to_date, savings_plan_used_commitment, split_line_item_actual_usage, split_line_item_net_split_cost, split_line_item_net_unused_cost, split_line_item_parent_resource_id, split_line_item_public_on_demand_split_cost, split_line_item_public_on_demand_unused_cost, split_line_item_reserved_usage, split_line_item_split_cost, split_line_item_split_usage, split_line_item_split_usage_ratio, split_line_item_unused_cost FROM COST_AND_USAGE_REPORT
      SQL
    }

    destination_configurations {
      s3_destination {
        s3_bucket = aws_s3_bucket.cur.bucket
        s3_prefix = var.report_prefix
        s3_region = var.region

        s3_output_configurations {
          compression = "PARQUET"
          format      = "PARQUET"
          output_type = "CUSTOM"
          overwrite   = "OVERWRITE_REPORT"
        }
      }
    }

    refresh_cadence {
      frequency = "SYNCHRONOUS"
    }
  }

  tags = {
    ManagedBy = "terraform"
    Purpose   = "CUR2"
  }
}

# -----------------------
# Glue IAM role & policy
# -----------------------
resource "aws_iam_role" "glue_crawler" {
  name = var.glue_crawler_role_name
  path = "/service-role/"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "glue.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })

  lifecycle {
    prevent_destroy = true
  }
}

# Attach AWS managed Glue service role policy
resource "aws_iam_role_policy_attachment" "glue_service_role" {
  role       = aws_iam_role.glue_crawler.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Custom S3 access for crawler to read CUR output
resource "aws_iam_policy" "glue_crawler_s3" {
  name        = "CURGlueCrawlerPolicy"
  description = "Policy for Glue Crawler and Job execution (CUR access). Do NOT delete!"
  path        = "/service-role/"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["s3:GetObject", "s3:PutObject"],
      Resource = [
        "arn:aws:s3:::${aws_s3_bucket.cur.id}/${var.report_prefix}/${var.cur_data_export_name}/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "glue_crawler_s3_attach" {
  role       = aws_iam_role.glue_crawler.name
  policy_arn = aws_iam_policy.glue_crawler_s3.arn
}

# -----------------------
# Glue Database & Crawler
# -----------------------
resource "aws_glue_catalog_database" "cur" {
  name       = var.glue_database_name
  catalog_id = data.aws_caller_identity.current.account_id

  lifecycle { prevent_destroy = true }
}

resource "aws_glue_crawler" "cur" {
  name          = var.crawler_name
  database_name = aws_glue_catalog_database.cur.name
  role          = aws_iam_role.glue_crawler.arn

  configuration = <<-JSON
    {"Version":1.0,"CrawlerOutput":{"Partitions":{"AddOrUpdateBehavior":"InheritFromTable"}},"Grouping":{"TableGroupingPolicy":"CombineCompatibleSchemas"},"CreatePartitionIndex":true}
  JSON

  recrawl_policy {
    recrawl_behavior = "CRAWL_EVERYTHING"
  }

  schema_change_policy {
    delete_behavior = "DELETE_FROM_DATABASE"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  s3_target {
    path = "s3://${aws_s3_bucket.cur.bucket}/${var.report_prefix}/${var.cur_data_export_name}/"
  }
}

# -----------------------
# Athena Workgroup & Query
# -----------------------
resource "aws_athena_workgroup" "cur" {
  name        = var.athena_workgroup_name
  description = "Workgroup for cost usage reports"

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.cur.bucket}/${var.cur_workgroup_query_prefix}/"
    }
  }
}

resource "aws_athena_named_query" "pipeline_costs" {
  name        = "Cost of pipeline jobs"
  database    = aws_glue_catalog_database.cur.name
  workgroup   = aws_athena_workgroup.cur.name
  description = "Query to estimate AWS Batch job costs"

  query = <<-SQL
    SELECT
      count(*)/2 AS num_jobs,
      resource_tags['user_pipeline_name'] AS pipeline_name,
      resource_tags['user_right_size_test'] AS right_size_test,
      resource_tags['user_launch_time'] AS launch_time,
      resource_tags['aws_batch_job_queue'] AS job_queue,
      sum(
          case when pricing_unit = 'vCPU-Hours'
          then split_line_item_public_on_demand_split_cost
          else 0 end) AS cpu_usage_public_cost,
      sum(
          case when pricing_unit = 'GB-Hours'
          then split_line_item_public_on_demand_split_cost
          else 0 end) as mem_usage_public_cost,
      sum(split_line_item_public_on_demand_split_cost) AS total_usage_public_cost,
      sum(split_line_item_public_on_demand_unused_cost) AS total_unused_capacity_public_cost
    FROM data
    WHERE
        line_item_operation = 'ECSTask-EC2' AND
        split_line_item_parent_resource_id IS NOT NULL AND
        contains(map_keys(resource_tags), 'user_pipeline_name') AND
        contains(map_keys(resource_tags), 'user_right_size_test') AND
        contains(map_keys(resource_tags), 'user_launch_time') AND
        contains(map_keys(resource_tags), 'aws_batch_job_queue') AND
        resource_tags['aws_batch_job_queue'] IN ('NextflowCPU', 'NextflowGPU')
    GROUP BY
        resource_tags['user_pipeline_name'],
        resource_tags['user_right_size_test'],
        resource_tags['user_launch_time'],
        resource_tags['aws_batch_job_queue']
    ORDER BY
        parse_datetime(resource_tags['user_launch_time'], 'yyyy-MM-dd_HH-mm-ss') DESC,
        resource_tags['user_right_size_test'],
        resource_tags['user_pipeline_name']
  SQL
}

# -----------------------
# Outputs
# -----------------------
output "cur_bucket_name" {
  value       = aws_s3_bucket.cur.bucket
  description = "S3 bucket receiving CUR 2.0 exports"
}

output "bcm_export_arn" {
  value       = aws_bcmdataexports_export.cur2.export_arn
  description = "ARN of the BCM Data Export"
}


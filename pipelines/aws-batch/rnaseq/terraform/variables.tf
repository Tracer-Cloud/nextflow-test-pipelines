variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "work_bucket_name" {
  description = "Name for the S3 work bucket (will append random suffix)"
  type        = string
  default     = "tracer-nxf-work"
}

variable "outputs_bucket_name" {
  description = "Name for the S3 outputs bucket (will append random suffix)"
  type        = string
  default     = "tracer-nxf-outputs"
}

variable "environment_name" {
  description = "Environment name for resource naming"
  type        = string
  default     = "rnaseq"
}

variable "create_instance_connect_endpoint" {
  description = "Whether to create EC2 Instance Connect Endpoint for private subnet access"
  type        = bool
  default     = false
}

variable "instance_types" {
  description = "List of EC2 instance types for AWS Batch compute (Amazon Linux)"
  type        = list(string)
  default     = ["m6i.large", "c6i.large", "r6i.large"]
}

variable "min_vcpus" {
  description = "Minimum vCPUs for compute environment"
  type        = number
  default     = 0
}

variable "max_vcpus" {
  description = "Maximum vCPUs for compute environment"
  type        = number
  default     = 1024
}

variable "bucket_suffix" {
  description = "Suffix to add to bucket names to make them unique (leave empty for auto-generated)"
  type        = string
  default     = ""
}

variable "create_batch_service_linked_role" {
  description = "Whether to create the AWS Batch service-linked role (set to false if it already exists)"
  type        = bool
  default     = false
}

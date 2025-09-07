output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "work_bucket" {
  description = "S3 work bucket name (with hash suffix)"
  value       = aws_s3_bucket.work.bucket
}

output "outputs_bucket" {
  description = "S3 outputs bucket name (with hash suffix)"
  value       = aws_s3_bucket.outputs.bucket
}

output "batch_cpu_job_queue_arn" {
  description = "AWS Batch CPU job queue ARN"
  value       = aws_batch_job_queue.cpu.arn
}

output "batch_cpu_job_queue_name" {
  description = "AWS Batch CPU job queue name"
  value       = aws_batch_job_queue.cpu.name
}


output "cpu_compute_environment_name" {
  description = "AWS Batch CPU compute environment name"
  value       = aws_batch_compute_environment.cpu.compute_environment_name
}

output "batch_gpu_job_queue_arn" {
  description = "AWS Batch GPU job queue ARN"
  value       = aws_batch_job_queue.gpu.arn
}

output "batch_gpu_job_queue_name" {
  description = "AWS Batch GPU job queue name"
  value       = aws_batch_job_queue.gpu.name
}

output "gpu_compute_environment_name" {
  description = "AWS Batch GPU compute environment name"
  value       = aws_batch_compute_environment.gpu.compute_environment_name
}


output "instance_connect_endpoint_id" {
  description = "EC2 Instance Connect Endpoint ID (if created)"
  value       = var.create_instance_connect_endpoint ? aws_ec2_instance_connect_endpoint.main[0].id : null
}

output "vpc_endpoints" {
  description = "VPC Endpoints created for private subnet connectivity"
  value = {
    s3_endpoint_id       = aws_vpc_endpoint.s3.id
    ec2_endpoint_id      = aws_vpc_endpoint.ec2.id
    ssm_endpoint_id      = aws_vpc_endpoint.ssm.id
    logs_endpoint_id     = aws_vpc_endpoint.logs.id
    ecs_endpoint_id      = aws_vpc_endpoint.ecs.id
  }
}

output "ecs_cluster_name" {
  description = "ECS Cluster name for AWS Batch"
  value       = aws_ecs_cluster.batch.name
}

output "ecs_cluster_arn" {
  description = "ECS Cluster ARN for AWS Batch"
  value       = aws_ecs_cluster.batch.arn
}

output "batch_job_role_arn" {
  description = "AWS Batch Job Role ARN for container tasks"
  value       = aws_iam_role.batch_job_role.arn
}

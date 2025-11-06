provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "tracer-rnaseq"
      Environment = "production"
      ManagedBy   = "terraform"
    }
  }
}

# ECS-optimized Amazon Linux 2023 AMI (region-specific) via SSM public parameter
data "aws_ssm_parameter" "ecs_al2023_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

# Get current AWS account ID and region for policy ARNs
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# VPC and Networking
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "tracer-rnaseq-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "tracer-rnaseq-igw"
  }
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name = "tracer-rnaseq-public-${count.index + 1}"
    Type = "Public"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "tracer-rnaseq-private-${count.index + 1}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "tracer-rnaseq-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway for private subnets
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "tracer-rnaseq-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "tracer-rnaseq-nat-gateway"
  }

  depends_on = [aws_internet_gateway.main]
}

# Route table for private subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "tracer-rnaseq-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Random string for unique bucket names
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Use unique suffix for IAM policy names to avoid conflicts
locals {
  policy_suffix = var.bucket_suffix != "" ? var.bucket_suffix : random_string.bucket_suffix.result
}

# S3 Buckets - Create with unique names using hash
resource "aws_s3_bucket" "work" {
  bucket = "${var.work_bucket_name}-${var.bucket_suffix != "" ? var.bucket_suffix : random_string.bucket_suffix.result}"

  tags = {
    Name = var.work_bucket_name
  }

  force_destroy = true
}

resource "aws_s3_bucket" "outputs" {
  bucket = "${var.outputs_bucket_name}-${var.bucket_suffix != "" ? var.bucket_suffix : random_string.bucket_suffix.result}"

  tags = {
    Name = var.outputs_bucket_name
  }

  force_destroy = true
}

resource "aws_s3_bucket_versioning" "work" {
  bucket = aws_s3_bucket.work.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "outputs" {
  bucket = aws_s3_bucket.outputs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "work" {
  bucket = aws_s3_bucket.work.id

  rule {
    id     = "delete-after-30-days"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket_public_access_block" "work" {
  bucket = aws_s3_bucket.work.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "outputs" {
  bucket = aws_s3_bucket.outputs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "work" {
  bucket = aws_s3_bucket.work.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_ownership_controls" "outputs" {
  bucket = aws_s3_bucket.outputs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_ecs_cluster" "batch" {
  name = "tracer-batch-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "tracer-batch-cluster"
  }
}

# IAM Role for Batch Instances
resource "aws_iam_role" "batch_instance_role" {
  name = "tracer-batch-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "batch_instance_profile" {
  name = "tracer-batch-instance-profile"
  role = aws_iam_role.batch_instance_role.name
}

resource "aws_iam_role_policy_attachment" "batch_instance_role_policy" {
  role       = aws_iam_role.batch_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "batch_instance_cloudwatch_policy" {
  role       = aws_iam_role.batch_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "batch_instance_ssm_core" {
  role       = aws_iam_role.batch_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "batch_instance_ssm_patch" {
  role       = aws_iam_role.batch_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMPatchAssociation"
}

resource "aws_iam_role_policy_attachment" "batch_instance_cloudwatch_agent" {
  role       = aws_iam_role.batch_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_policy" "batch_s3_policy" {
  name        = "tracer-batch-s3-policy-${local.policy_suffix}"
  description = "Full S3 access policy for batch instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "s3-object-lambda:*"
        ]
        Resource = "*"
      }
    ]
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "batch_instance_s3_policy" {
  role       = aws_iam_role.batch_instance_role.name
  policy_arn = aws_iam_policy.batch_s3_policy.arn
}

# Security Groups
resource "aws_security_group" "batch" {
  name        = "tracer-batch-sg"
  description = "Security group for batch instances - completely open"
  vpc_id      = aws_vpc.main.id

  # Allow ALL inbound traffic
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all inbound traffic"
  }

  # Allow ALL outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "tracer-batch-sg"
  }
}

# EC2 Instance Connect Endpoint (optional - may fail due to quota limits)
resource "aws_security_group" "eice" {
  name        = "tracer-eice-sg"
  description = "Security group for EC2 Instance Connect Endpoint"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tracer-eice-sg"
  }
}

# VPC Endpoints for private subnet connectivity
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name = "tracer-s3-endpoint"
  }
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "tracer-ec2-endpoint"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "tracer-ssm-endpoint"
  }
}

resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "tracer-ssm-messages-endpoint"
  }
}

resource "aws_vpc_endpoint" "ec2_messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "tracer-ec2-messages-endpoint"
  }
}

resource "aws_vpc_endpoint" "ecs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "tracer-ecs-endpoint"
  }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "tracer-logs-endpoint"
  }
}

# Security group for VPC endpoints
resource "aws_security_group" "vpc_endpoints" {
  name        = "tracer-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tracer-vpc-endpoints-sg"
  }
}

resource "aws_ec2_instance_connect_endpoint" "main" {
  count = var.create_instance_connect_endpoint ? 1 : 0
  
  subnet_id          = aws_subnet.private[0].id
  security_group_ids = [aws_security_group.eice.id]

  tags = {
    Name = "tracer-instance-connect-endpoint"
  }

  timeouts {
    create = "10m"
    delete = "10m"
  }

  lifecycle {
    ignore_changes = [subnet_id]
  }
}

resource "aws_security_group_rule" "batch_allow_ssh_from_eice" {
  type                     = "ingress"
  security_group_id        = aws_security_group.batch.id
  source_security_group_id = aws_security_group.eice.id
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "eice_allow_ssh_to_batch" {
  type                     = "egress"
  security_group_id        = aws_security_group.eice.id
  source_security_group_id = aws_security_group.batch.id
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
}

# Launch Template
resource "aws_launch_template" "batch" {
  name_prefix = "tracer-batch-lt"
  image_id    = data.aws_ssm_parameter.ecs_al2023_ami.value

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 500
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = false
    }
  }

  metadata_options {
    http_tokens                 = "required"
    instance_metadata_tags      = "enabled"
  }

  vpc_security_group_ids = [aws_security_group.batch.id]

  user_data = base64encode(templatefile("${path.module}/user_data_mime.sh", {
    cluster_name = aws_ecs_cluster.batch.name
  }))

  iam_instance_profile {
    name = aws_iam_instance_profile.batch_instance_profile.name
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "tracer-batch-instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# AWS Batch Job Role (for tasks running in containers)
resource "aws_iam_role" "batch_job_role" {
  name = "tracer-batch-job-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "batch_job_s3_policy" {
  role       = aws_iam_role.batch_job_role.name
  policy_arn = aws_iam_policy.batch_s3_policy.arn
}

# AWS Batch Service Role
resource "aws_iam_role" "batch_service_role" {
  name = "tracer-batch-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "batch.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "batch_service_role_policy" {
  role       = aws_iam_role.batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

# Add additional service role policy for compute environment management
resource "aws_iam_role_policy_attachment" "batch_service_role_ec2_policy" {
  role       = aws_iam_role.batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Add EC2 Spot Fleet permissions
resource "aws_iam_role_policy_attachment" "batch_service_role_spot_fleet_policy" {
  role       = aws_iam_role.batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
}

# Add ECS permissions for batch service role
resource "aws_iam_role_policy_attachment" "batch_service_role_ecs_policy" {
  role       = aws_iam_role.batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Try to create service-linked role for AWS Batch, ignore if exists
resource "aws_iam_service_linked_role" "batch" {
  count            = var.create_batch_service_linked_role ? 1 : 0
  aws_service_name = "batch.amazonaws.com"
  description      = "Service-linked role for AWS Batch"
}

# Additional IAM policy for batch instances (similar to CloudFormation)
resource "aws_iam_policy" "batch_additional_permissions" {
  name        = "tracer-batch-additional-permissions-${local.policy_suffix}"
  description = "Additional permissions for batch instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSBatchPolicyStatement1"
        Effect = "Allow"
        Action = [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeKeyPairs",
          "ec2:DescribeImages",
          "ec2:DescribeImageAttribute",
          "ec2:DescribeSpotInstanceRequests",
          "ec2:DescribeSpotFleetInstances",
          "ec2:DescribeSpotFleetRequests",
          "ec2:DescribeSpotPriceHistory",
          "ec2:DescribeSpotFleetRequestHistory",
          "ec2:DescribeVpcClassicLink",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:CreateLaunchTemplate",
          "ec2:DeleteLaunchTemplate",
          "ec2:RequestSpotFleet",
          "ec2:CancelSpotFleetRequests",
          "ec2:ModifySpotFleetRequest",
          "ec2:TerminateInstances",
          "ec2:RunInstances",
          "autoscaling:DescribeAccountLimits",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:CreateLaunchConfiguration",
          "autoscaling:CreateAutoScalingGroup",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:DeleteLaunchConfiguration",
          "autoscaling:DeleteAutoScalingGroup",
          "autoscaling:CreateOrUpdateTags",
          "autoscaling:SuspendProcesses",
          "autoscaling:PutNotificationConfiguration",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ecs:DescribeClusters",
          "ecs:DescribeContainerInstances",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListAccountSettings",
          "ecs:ListClusters",
          "ecs:ListContainerInstances",
          "ecs:ListTaskDefinitionFamilies",
          "ecs:ListTaskDefinitions",
          "ecs:ListTasks",
          "ecs:CreateCluster",
          "ecs:DeleteCluster",
          "ecs:RegisterTaskDefinition",
          "ecs:DeregisterTaskDefinition",
          "ecs:RunTask",
          "ecs:StartTask",
          "ecs:StopTask",
          "ecs:UpdateContainerAgent",
          "ecs:DeregisterContainerInstance",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "iam:GetInstanceProfile",
          "iam:GetRole"
        ]
        Resource = "*"
      },
      {
        Sid      = "AWSBatchPolicyStatement2"
        Effect   = "Allow"
        Action   = "ecs:TagResource"
        Resource = [
          "arn:aws:ecs:*:*:task/*_Batch_*"
        ]
      },
      {
        Sid      = "AWSBatchPolicyStatement3"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = [
              "ec2.amazonaws.com",
              "ec2.amazonaws.com.cn",
              "ecs-tasks.amazonaws.com"
            ]
          }
        }
      },
      {
        Sid      = "AWSBatchPolicyStatement4"
        Effect   = "Allow"
        Action   = "iam:CreateServiceLinkedRole"
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = [
              "spot.amazonaws.com",
              "spotfleet.amazonaws.com",
              "autoscaling.amazonaws.com",
              "ecs.amazonaws.com"
            ]
          }
        }
      },
      {
        Sid      = "AWSBatchPolicyStatement5"
        Effect   = "Allow"
        Action   = "ec2:CreateTags"
        Resource = "*"
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = "RunInstances"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "s3-object-lambda:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:rds*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:DescribeInstanceInformation",
          "ssm:StartSession"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "pricing:GetProducts"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:CreateCluster",
          "ecs:DeregisterContainerInstance",
          "ecs:DiscoverPollEndpoint",
          "ecs:Poll",
          "ecs:RegisterContainerInstance",
          "ecs:StartTelemetrySession",
          "ecs:Submit*",
          "ecs:UpdateContainerInstancesState"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "batch_instance_additional_policy" {
  role       = aws_iam_role.batch_instance_role.name
  policy_arn = aws_iam_policy.batch_additional_permissions.arn
}

# CPU Compute Environment
resource "aws_batch_compute_environment" "cpu" {
  compute_environment_name = "tracer-rnaseq-cpu-compute-env"
  service_role            = aws_iam_role.batch_service_role.arn
  type                   = "MANAGED"
  state                  = "ENABLED"

  compute_resources {
    type                = "EC2"
    allocation_strategy = "BEST_FIT_PROGRESSIVE"
    min_vcpus          = 0
    max_vcpus          = var.max_vcpus
    desired_vcpus      = 0

    instance_type = ["optimal"]

    subnets = aws_subnet.public[*].id
    
    security_group_ids = [aws_security_group.batch.id]

    instance_role = aws_iam_instance_profile.batch_instance_profile.arn

    # Use ECS-optimized Amazon Linux 2023
    ec2_configuration {
      image_type = "ECS_AL2023"
    }

    launch_template {
      launch_template_id = aws_launch_template.batch.id
      version            = "$Latest"
    }

    tags = {
      Name = "tracer-batch-compute"
      Environment = "production"
    }
  }

  depends_on = [
    aws_ecs_cluster.batch,
    aws_iam_role_policy_attachment.batch_service_role_policy,
    aws_iam_role_policy_attachment.batch_service_role_ec2_policy,
    aws_iam_role_policy_attachment.batch_service_role_ecs_policy,
    aws_iam_role_policy_attachment.batch_instance_additional_policy,
    aws_launch_template.batch,
  ]
  
  tags = {
    Name = "tracer-rnaseq-cpu-compute-env"
  }

  lifecycle {
    ignore_changes = [
      compute_resources[0].desired_vcpus
    ]
  }
}


# GPU Compute Environment
resource "aws_batch_compute_environment" "gpu" {
  compute_environment_name = "tracer-rnaseq-gpu-compute-env"
  service_role            = aws_iam_role.batch_service_role.arn
  type                   = "MANAGED"
  state                  = "ENABLED"

  compute_resources {
    type                = "EC2"
    allocation_strategy = "BEST_FIT_PROGRESSIVE"
    min_vcpus          = 0
    max_vcpus          = 256
    desired_vcpus      = 0

    instance_type = ["optimal"]

    subnets = aws_subnet.public[*].id
    
    security_group_ids = [aws_security_group.batch.id]

    instance_role = aws_iam_instance_profile.batch_instance_profile.arn

    ec2_configuration {
      image_type = "ECS_AL2_NVIDIA"
    }

    launch_template {
      launch_template_id = aws_launch_template.batch.id
      version            = "$Latest"
    }

    tags = {
      Name = "tracer-batch-gpu-compute"
      Environment = "production"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.batch_service_role_policy,
    aws_iam_role_policy_attachment.batch_service_role_ec2_policy,
    aws_iam_role_policy_attachment.batch_service_role_ecs_policy,
    aws_iam_role_policy_attachment.batch_instance_additional_policy,
    aws_launch_template.batch,
    aws_ecs_cluster.batch
  ]
  
  tags = {
    Name = "tracer-rnaseq-gpu-compute-env"
  }

  lifecycle {
    ignore_changes = [
      compute_resources[0].desired_vcpus
    ]
  }
}

# CPU Job Queue
resource "aws_batch_job_queue" "cpu" {
  name     = "NextflowCPU"
  state    = "ENABLED"
  priority = 1

  compute_environment_order {
    compute_environment = aws_batch_compute_environment.cpu.arn
    order              = 1
  }

  lifecycle {
    create_before_destroy = false
  }
}

# GPU Job Queue
resource "aws_batch_job_queue" "gpu" {
  name     = "NextflowGPU"
  state    = "ENABLED"
  priority = 1

  compute_environment_order {
    compute_environment = aws_batch_compute_environment.gpu.arn
    order              = 1
  }

  lifecycle {
    create_before_destroy = false
  }
}



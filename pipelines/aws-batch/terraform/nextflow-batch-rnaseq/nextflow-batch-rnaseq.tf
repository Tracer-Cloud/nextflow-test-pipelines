terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

provider "aws" {
  region = var.region
}

# =======================
# VPC + Public Subnets
# =======================
data "aws_availability_zones" "this" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "nextflow-batch-rnaseq-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "nextflow-batch-rnaseq-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "nextflow-batch-rnaseq-public-rt" }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/20"
  availability_zone       = data.aws_availability_zones.this.names[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "nextflow-batch-rnaseq-public-a" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.16.0/20"
  availability_zone       = data.aws_availability_zones.this.names[1]
  map_public_ip_on_launch = true
  tags                    = { Name = "nextflow-batch-rnaseq-public-b" }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

locals {
  public_subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

# =======================
# Buckets
# =======================
variable "nextflow_work_bucket" {
  type    = string
  default = "tracer-nxf-rnaseq-work"
}

variable "nextflow_outputs_bucket" {
  type    = string
  default = "tracer-nxf-rnaseq-outputs"
}

resource "aws_s3_bucket" "work" {
  bucket        = var.nextflow_work_bucket
  force_destroy = false
}

resource "aws_s3_bucket_lifecycle_configuration" "work" {
  bucket = aws_s3_bucket.work.id

  rule {
    id     = "DeleteAfter30Days"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "work" {
  bucket = aws_s3_bucket.work.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "work" {
  bucket                  = aws_s3_bucket.work.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket" "outputs" {
  bucket        = var.nextflow_outputs_bucket
  force_destroy = false
}

resource "aws_s3_bucket_ownership_controls" "outputs" {
  bucket = aws_s3_bucket.outputs.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "outputs" {
  bucket                  = aws_s3_bucket.outputs.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

# =======================
# IAM for Batch instances
# =======================
resource "aws_iam_role" "batch_instance_role" {
  name = "NextflowBatchRnaseqInstanceIAMRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = ["ec2.amazonaws.com"] },
      Action    = ["sts:AssumeRole"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_for_ec2" {
  role       = aws_iam_role.batch_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "cw_agent" {
  role       = aws_iam_role.batch_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy" "s3_access" {
  name = "S3Access"
  role = aws_iam_role.batch_instance_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:PutObject"],
        Resource = "arn:aws:s3:::${aws_s3_bucket.work.id}/*"
      },
      {
        Effect   = "Allow",
        Action   = ["s3:PutObject"],
        Resource = "arn:aws:s3:::${aws_s3_bucket.outputs.id}/metrics/*"
      },
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject", "s3:GetObjectVersion", "s3:HeadObject", "s3:ListBucket", "s3:PutObject"],
        Resource = "arn:aws:s3:::*"
      },
      {
        Effect   = "Allow",
        Action   = ["pricing:GetProducts"],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["ec2:*"],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "aws_batch_policy" {
  name = "AWSBatchRnaseqPolicy"
  role = aws_iam_role.batch_instance_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AWSBatchPolicyStatement1",
        Effect = "Allow",
        Action = [
          "ec2:DescribeAccountAttributes", "ec2:DescribeInstances", "ec2:DescribeInstanceStatus",
          "ec2:DescribeInstanceAttribute", "ec2:DescribeSubnets", "ec2:DescribeSecurityGroups",
          "ec2:DescribeKeyPairs", "ec2:DescribeImages", "ec2:DescribeImageAttribute",
          "ec2:DescribeSpotInstanceRequests", "ec2:DescribeSpotFleetInstances",
          "ec2:DescribeSpotFleetRequests", "ec2:DescribeSpotPriceHistory",
          "ec2:DescribeSpotFleetRequestHistory", "ec2:DescribeVpcClassicLink",
          "ec2:DescribeLaunchTemplateVersions", "ec2:CreateLaunchTemplate", "ec2:DeleteLaunchTemplate",
          "ec2:RequestSpotFleet", "ec2:CancelSpotFleetRequests", "ec2:ModifySpotFleetRequest",
          "ec2:TerminateInstances", "ec2:RunInstances",
          "autoscaling:DescribeAccountLimits", "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeLaunchConfigurations", "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeScalingActivities", "autoscaling:CreateLaunchConfiguration",
          "autoscaling:CreateAutoScalingGroup", "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:SetDesiredCapacity", "autoscaling:DeleteLaunchConfiguration",
          "autoscaling:DeleteAutoScalingGroup", "autoscaling:CreateOrUpdateTags",
          "autoscaling:SuspendProcesses", "autoscaling:PutNotificationConfiguration",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ecs:DescribeClusters", "ecs:DescribeContainerInstances", "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks", "ecs:ListAccountSettings", "ecs:ListClusters", "ecs:ListContainerInstances",
          "ecs:ListTaskDefinitionFamilies", "ecs:ListTaskDefinitions", "ecs:ListTasks",
          "ecs:CreateCluster", "ecs:DeleteCluster", "ecs:RegisterTaskDefinition", "ecs:DeregisterTaskDefinition",
          "ecs:RunTask", "ecs:StartTask", "ecs:StopTask", "ecs:UpdateContainerAgent", "ecs:DeregisterContainerInstance",
          "logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogGroups",
          "iam:GetInstanceProfile", "iam:GetRole"
        ],
        Resource = "*"
      },
      {
        Sid      = "AWSBatchPolicyStatement2",
        Effect   = "Allow",
        Action   = "ecs:TagResource",
        Resource = "arn:aws:ecs:*:*:task/*_Batch_*"
      },
      {
        Sid      = "AWSBatchPolicyStatement3",
        Effect   = "Allow",
        Action   = "iam:PassRole",
        Resource = "*",
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
        Sid      = "AWSBatchPolicyStatement4",
        Effect   = "Allow",
        Action   = "iam:CreateServiceLinkedRole",
        Resource = "*",
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
        Sid      = "AWSBatchPolicyStatement5",
        Effect   = "Allow",
        Action   = "ec2:CreateTags",
        Resource = "*",
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = "RunInstances"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "additional_permissions" {
  name = "AdditionalPermissions"
  role = aws_iam_role.batch_instance_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect = "Allow", Action = ["s3:*", "s3-object-lambda:*"], Resource = "*" },
      {
        Effect   = "Allow",
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret", "secretsmanager:ListSecrets"],
        Resource = "arn:aws:secretsmanager:*:*:secret:rds*"
      },
      {
        Effect   = "Allow",
        Action   = ["ssm:GetParameter", "ssm:DescribeInstanceInformation", "ssm:StartSession"],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "batch_instance_profile" {
  name = "NextflowBatchRnaseqInstanceProfile"
  role = aws_iam_role.batch_instance_role.name
}

# =======================
# Security Groups + EICE
# =======================
resource "aws_security_group" "eice_sg" {
  name        = "InstanceConnectEndpointSecurityGroup"
  description = "EC2 Instance Connect Endpoint Security Group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow all (required by EICE control-plane)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "batch_sg" {
  name        = "NextflowBatchRnaseqSecurityGroup"
  description = "Nextflow Batch EC2 Security Group"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Allow SSH from EICE to Batch instances
resource "aws_security_group_rule" "eice_to_batch_egress_22" {
  type                     = "egress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eice_sg.id
  source_security_group_id = aws_security_group.batch_sg.id
}

resource "aws_security_group_rule" "batch_from_eice_ingress_22" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.batch_sg.id
  source_security_group_id = aws_security_group.eice_sg.id
}

resource "aws_ec2_instance_connect_endpoint" "eice" {
  subnet_id          = aws_subnet.public_a.id
  security_group_ids = [aws_security_group.eice_sg.id]
}

# =======================
# Launch Template
# =======================
locals {
  nextflow_user_data = <<-USERDATA
    MIME-Version: 1.0
    Content-Type: multipart/mixed; boundary="==BOUNDARY=="

    --==BOUNDARY==
    MIME-Version: 1.0
    Content-Type: text/cloud-config; charset="us-ascii"

    #cloud-config
    yum_repos:
      vector:
        name: Vector
        baseurl: https://yum.vector.dev/stable/vector-0/$basearch/
        enabled: true
        gpgcheck: true
        gpgkey: https://keys.datadoghq.com/DATADOG_RPM_KEY_CURRENT.public
        priority: 1
    packages:
      - ec2-instance-connect
      - groff
      - less
      - patchelf
      - unzip
      - vector
    runcmd:
      - echo ECS_MANIFEST_PULL_TIMEOUT=60m >> /etc/ecs/ecs.config
      - echo ECS_CONTAINER_START_TIMEOUT=60m >> /etc/ecs/ecs.config
      - echo ECS_CONTAINER_CREATE_TIMEOUT=60m >> /etc/ecs/ecs.config
      - echo ECS_DISABLE_IMAGE_CLEANUP=true >> /etc/ecs/ecs.config
      - echo ECS_IMAGE_PULL_BEHAVIOR=once >> /etc/ecs/ecs.config
      - echo ECS_RESERVED_MEMORY=256 >> /etc/ecs/ecs.config
      - |
        echo '{"max-concurrent-downloads": 1}' > /etc/docker/daemon.json
      - curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip
      - unzip awscliv2.zip
      - ./aws/install
      - patchelf --force-rpath --no-sort --set-rpath '$ORIGIN/../dist' /usr/local/aws-cli/v2/current/bin/aws
      - sed -i -e 's/validate/validate --skip-healthchecks/' -e '/^AmbientCapabilities=/ s/$/ CAP_DAC_READ_SEARCH/' /usr/lib/systemd/system/vector.service
      - systemctl daemon-reload
      - systemctl start vector
      - echo "Installing tracer"
      - curl -sSL https://88872bab.tracer-client.pages.dev/installation-script-development.sh | bash -s -- TestBatchAWSEnvironmentNew
      - TRACER_DATABASE_HOST=tracer-cluster-v2.cluster-cdgizpzxtdp6.us-east-1.rds.amazonaws.com TRACER_DATABASE_NAME=tracer_db TRACER_DATABASE_SECRETS_ARN=arn:aws:secretsmanager:us-east-1:395261708130:secret:rds!cluster-cd690a09-953c-42e9-9d9f-1ed0b434d226-M0wZYA /.tracerbio/bin/tracer init --pipeline-name TestBatchAWSEnvironmentNew --environment aws_batch --pipeline-type rnaseq --user-id aws_batch
    write_files:
      - path: /etc/vector/vector.yaml
        content: |
          sources:
            ecs_init: { type: file, include: ["/var/log/ecs/ecs-init.log"] }
            ecs_agent: { type: file, include: ["/var/log/ecs/ecs-agent.log"] }
            cloud_init: { type: file, include: ["/var/log/cloud-init.log"] }
            journald: { type: journald }
            host_metrics: { type: host_metrics, scrape_interval_secs: 60 }
          transforms:
            ecs_init_log_group: { type: remap, inputs: [ecs_init], source: '."group-name" = "/ecs/init"' }
            ecs_agent_log_group: { type: remap, inputs: [ecs_agent], source: '."group-name" = "/ecs/agent"' }
            cloud_init_log_group: { type: remap, inputs: [cloud_init], source: '."group-name" = "/cloud-init"' }
            journald_interesting: { type: filter, inputs: [journald], condition: { type: vrl, source: "to_int(.PRIORITY) <= 4 ?? false" } }
            journald_log_group: { type: remap, inputs: [journald_interesting], source: '."group-name" = "/journald"' }
            add_log_metadata:
              type: aws_ec2_metadata
              inputs: [ecs_init_log_group, ecs_agent_log_group, cloud_init_log_group, journald_log_group]
              fields: ["instance-id","instance-type","ami-id"]
              tags: ["aws:autoscaling:groupName"]
              required: false
            add_metrics_metadata:
              type: aws_ec2_metadata
              inputs: [host_metrics]
              fields: ["instance-id","instance-type","ami-id"]
              tags: ["aws:autoscaling:groupName"]
              required: false
          sinks:
            cloudwatch_logs:
              type: aws_cloudwatch_logs
              inputs: [add_log_metadata]
              group_name: '{{ ."group-name" }}'
              stream_name: '{{ ."instance-id" }}'
              retention: { days: 14, enabled: true }
              encoding: { codec: json }
            cloudwatch_metrics:
              type: aws_cloudwatch_metrics
              inputs: [add_metrics_metadata]
              default_namespace: default
    --==BOUNDARY==--
  USERDATA
}

resource "aws_launch_template" "nextflow" {
  name = "NextflowBatchRnaseqLaunchTemplate"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = true
      encrypted             = false
      volume_size           = 500
      volume_type           = "gp3"
    }
  }

  metadata_options {
    http_tokens            = "required"
    instance_metadata_tags = "enabled"
  }

  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    device_index                = 0
    security_groups             = [aws_security_group.batch_sg.id]
  }

  user_data = base64encode(local.nextflow_user_data)
}

# =======================
# Batch Compute Environments + Queues
# =======================
resource "aws_batch_compute_environment" "gpu" {
  # If your provider errors on this line, remove it or upgrade the AWS provider.
  name = "NextflowBatchRnaseqGPUComputeEnvironment"

  type  = "MANAGED"
  state = "ENABLED"

  compute_resources {
    type                = "EC2"
    allocation_strategy = "BEST_FIT_PROGRESSIVE"
    min_vcpus           = 0
    desired_vcpus       = 0
    max_vcpus           = 256
    instance_role       = aws_iam_instance_profile.batch_instance_profile.arn
    instance_type       = ["g4dn"]

    ec2_configuration {
      image_type = "ECS_AL2_NVIDIA"
    }

    launch_template {
      launch_template_id = aws_launch_template.nextflow.id
      version            = aws_launch_template.nextflow.latest_version
    }

    subnets = local.public_subnet_ids
  }
}

resource "aws_batch_job_queue" "gpu" {
  name     = "NextflowRnaseqGPU"
  state    = "ENABLED"
  priority = 1

  compute_environment_order {
    order               = 1
    compute_environment = aws_batch_compute_environment.gpu.arn
  }
}

resource "aws_batch_compute_environment" "m_cpu" {
  name = "NextflowRnaseqMCPUComputeEnvironment"

  type  = "MANAGED"
  state = "ENABLED"

  compute_resources {
    type                = "EC2"
    allocation_strategy = "BEST_FIT_PROGRESSIVE"
    min_vcpus           = 0
    desired_vcpus       = 0
    max_vcpus           = 1024
    instance_role       = aws_iam_instance_profile.batch_instance_profile.arn
    instance_type       = ["m7a", "m7i", "m6a", "m6i", "m5a", "m5"]

    ec2_configuration {
      image_type = "ECS_AL2023"
    }

    launch_template {
      launch_template_id = aws_launch_template.nextflow.id
      version            = aws_launch_template.nextflow.latest_version
    }

    subnets = local.public_subnet_ids
  }
}

resource "aws_batch_job_queue" "m_cpu" {
  name     = "NextflowRnaseqMCPU"
  state    = "ENABLED"
  priority = 1

  compute_environment_order {
    order               = 1
    compute_environment = aws_batch_compute_environment.m_cpu.arn
  }
}

resource "aws_batch_compute_environment" "c_cpu" {
  name = "NextflowRnaseqCCPUComputeEnvironment"

  type  = "MANAGED"
  state = "ENABLED"

  compute_resources {
    type                = "EC2"
    allocation_strategy = "BEST_FIT_PROGRESSIVE"
    min_vcpus           = 0
    desired_vcpus       = 0
    max_vcpus           = 1024
    instance_role       = aws_iam_instance_profile.batch_instance_profile.arn
    instance_type       = ["c7a", "c7i", "c6a", "c6i", "c5a", "c5"]

    ec2_configuration {
      image_type = "ECS_AL2023"
    }

    launch_template {
      launch_template_id = aws_launch_template.nextflow.id
      version            = aws_launch_template.nextflow.latest_version
    }

    subnets = local.public_subnet_ids
  }
}

resource "aws_batch_job_queue" "c_cpu" {
  name     = "NextflowRnaseqCCPU"
  state    = "ENABLED"
  priority = 1

  compute_environment_order {
    order               = 1
    compute_environment = aws_batch_compute_environment.c_cpu.arn
  }
}

resource "aws_batch_compute_environment" "r_cpu" {
  name = "NextflowRnaseqRCPUComputeEnvironment"

  type  = "MANAGED"
  state = "ENABLED"

  compute_resources {
    type                = "EC2"
    allocation_strategy = "BEST_FIT_PROGRESSIVE"
    min_vcpus           = 0
    desired_vcpus       = 0
    max_vcpus           = 1024
    instance_role       = aws_iam_instance_profile.batch_instance_profile.arn
    instance_type       = ["r7a", "r7i", "r6a", "r6i", "r5a", "r5"]

    ec2_configuration {
      image_type = "ECS_AL2023"
    }

    launch_template {
      launch_template_id = aws_launch_template.nextflow.id
      version            = aws_launch_template.nextflow.latest_version
    }

    subnets = local.public_subnet_ids
  }
}

resource "aws_batch_job_queue" "r_cpu" {
  name     = "NextflowRnaseqRCPU"
  state    = "ENABLED"
  priority = 1

  compute_environment_order {
    order               = 1
    compute_environment = aws_batch_compute_environment.r_cpu.arn
  }
}

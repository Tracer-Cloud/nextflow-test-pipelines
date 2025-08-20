# Automatically Provision EC2 + Run WDL Pipeline
- Shuts down in 20 min

Run command: 
- bash pipelines/linux-x86-ubuntu/wdl-auto-ec2/run.sh


Requirements

AWS CLI configured with credentials & default region.

Existing EC2 key pair (for optional SSH access).

IAM permissions: ec2:RunInstances, ec2:TerminateInstances, ec2:Describe*, ec2:CreateSecurityGroup, ec2:AuthorizeSecurityGroupIngress.

Deliverable

A single bash script (run.sh) that:

Finds latest Ubuntu 22.04 AMI in the target region.

Creates (or reuses) a security group with SSH allowed (port 22).

Launches an EC2 instance (t3.medium) with user-data:

Install Java, Git, Cromwell.

Clone workflow repo.

Run fastq_subsample.wdl with inputs in the background.

Log output to /var/log/cromwell-run.log.

Schedule auto-shutdown in 20 min (shutdown -h +20).

Prints outputs:

Instance ID.

Public IP.

Direct AWS Console link to instance.

SSH command for debugging.

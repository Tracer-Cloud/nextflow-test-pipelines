#!/bin/bash

# Launch EC2 instance with user-data to run WDL pipeline
#
# Setup Requirements:
# - Linux x86_64 system
# - At least 2GB RAM and 1 vCPU
# - Pixi (will be installed automatically if missing)
#
# AWS Recommendations:
# - Instance Type: c7a.4xlarge
# - Disk Space: 200GB (to be sure)
#
set -euo pipefail

# --- Configurable variables ---
KEY_NAME=rapid-ec2-v1           # must exist in your account/region
AMI_ID=$(aws ec2 describe-images \
  --owners 099720109477 \
  --filters 'Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*' \
  --query 'Images | sort_by(@,&CreationDate)[-1].ImageId' \
  --output text)

INSTANCE_TYPE=c7a.4xlarge
REGION=us-east-1

echo "Using AMI: $AMI_ID"

# --- Read user data script from file ---
USERDATA=$(cat user-data.sh)

# --- Launch instance ---
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --count 1 \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --region $REGION \
  --user-data "$USERDATA" \
  --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":200,"VolumeType":"gp3"}}]' \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Launched instance: $INSTANCE_ID"

# Wait until running
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION

# Fetch public IP
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID --region $REGION \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

echo "Instance ready at: $PUBLIC_IP"
echo "SSH: ssh -i $KEY_NAME.pem ubuntu@$PUBLIC_IP"
echo "Logs: check /var/log/user-data.log and /var/log/wdl-completion.log"

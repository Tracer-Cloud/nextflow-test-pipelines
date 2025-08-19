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

# --- User confirmation ---
echo "Please confirm the following settings:"
echo ""
echo "Tracer User ID: user_2y5dYWwh7RlZWKDOPl7E0LeQGh1"
read -p "Is this the correct Tracer User ID? (y/N): " confirm_user_id
if [[ ! "$confirm_user_id" =~ ^[Yy]$ ]]; then
    echo "Please update the user_id in user-data.sh and run again."
    exit 1
fi

echo ""

echo "EC2 Key Name: rapid-ec2-v1"
read -p "Is this the correct EC2 key name in your account? (y/N): " confirm_key_name
if [[ ! "$confirm_key_name" =~ ^[Yy]$ ]]; then
    read -p "Please enter your EC2 key name: " user_key_name
    if [[ -z "$user_key_name" ]]; then
        echo "No key name provided. Exiting."
        exit 1
    fi
    KEY_NAME="$user_key_name"
    echo "Using key name: $KEY_NAME"
else
    KEY_NAME=rapid-ec2-v1
fi

echo ""
echo "Proceeding with instance launch..."
echo ""

# --- Configurable variables ---
# KEY_NAME is now set based on user input

AMI_ID=$(aws ec2 describe-images \
  --owners 099720109477 \
  --filters 'Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*' \
  --query 'Images | sort_by(@,&CreationDate)[-1].ImageId' \
  --output text)

INSTANCE_TYPE=c7a.4xlarge
REGION=us-east-1

# --- Create security group for EC2 Instance Connect ---
SECURITY_GROUP_NAME="wdl-instance-connect-sg"
SG_ID=$(aws ec2 describe-security-groups \
  --filters Name=group-name,Values=$SECURITY_GROUP_NAME \
  --query "SecurityGroups[0].GroupId" --output text --region $REGION 2>/dev/null || echo "None")

if [[ "$SG_ID" == "None" ]]; then
  echo "Creating security group for EC2 Instance Connect..."
  VPC_ID=$(aws ec2 describe-vpcs --query 'Vpcs[0].VpcId' --output text --region $REGION)
  SG_ID=$(aws ec2 create-security-group \
    --group-name $SECURITY_GROUP_NAME \
    --description "Security group for WDL pipeline with EC2 Instance Connect" \
    --vpc-id $VPC_ID \
    --region $REGION \
    --query 'GroupId' --output text)

  # Add rule for EC2 Instance Connect (port 22 from EC2 Instance Connect service)
  aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr 18.206.107.24/29 \
    --region $REGION > /dev/null 2>&1

  # Add rule for regular SSH (optional - remove if you only want Instance Connect)
  aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 \
    --region $REGION > /dev/null 2>&1

  echo "Security group created successfully!"
fi

echo "Using AMI: $AMI_ID"
echo "Using Security Group: $SG_ID"

# --- Read user data script from file ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USERDATA=$(cat "$SCRIPT_DIR/user-data.sh")

# --- Launch instance ---
INSTANCE_NAME="auto-wdl-user-id-user_2y5dYWwh7RlZWKDOPl7E0LeQGh1"
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --count 1 \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SG_ID \
  --region $REGION \
  --user-data "$USERDATA" \
  --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":200,"VolumeType":"gp3"}}]' \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Launched instance: $INSTANCE_NAME ($INSTANCE_ID)"

# Wait until running
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION

# Fetch public IP
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID --region $REGION \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

echo "Instance ready at: $PUBLIC_IP"
echo "SSH: ssh -i $KEY_NAME.pem ubuntu@$PUBLIC_IP"
echo "Logs: check /var/log/user-data.log and /var/log/wdl-completion.log"
echo ""
echo "AWS Console Link:"
echo "https://console.aws.amazon.com/ec2/home?region=$REGION#InstanceDetails:instanceId=$INSTANCE_ID"

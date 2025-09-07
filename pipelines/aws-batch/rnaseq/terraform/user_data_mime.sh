Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="
MIME-Version: 1.0

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash

set -e
set +e

# Log dirs for storing setup logs
mkdir -p /var/log/tracer
chmod 755 /var/log/tracer
exec > >(tee /var/log/user-data.log /var/log/tracer/script.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=== Starting AWS Batch Instance Bootstrap ==="
echo "Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
echo "Instance Type: $(curl -s http://169.254.169.254/latest/meta-data/instance-type)"
echo "Availability Zone: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)"
echo "Start time: $(date)"

yum update -y

for package in ec2-instance-connect groff less patchelf unzip curl wget util-linux htop iotop docker amazon-cloudwatch-agent java-17-amazon-corretto zlib zlib-devel zlib.i686 zlib.i386 glibc glibc-devel glibc-static libgcc libgcc.i686 libstdc++ libstdc++-devel libstdc++-static gcc gcc-c++ make libgcc.i686 libstdc++.i686 ncurses-libs.i686; do
    echo "Installing $package..."
    yum install -y $package || echo "Warning: Failed to install $package, continuing..."
done

# Verify critical libraries are available
ldconfig
ldconfig -p | grep -E "(libz\.so|libgcc_s\.so|libstdc\+\+\.so)" || echo "Warning: Some libraries not found in cache"

yum install -y ecs-init

# Configure ECS
echo "Configuring ECS..."
cat > /etc/ecs/ecs.config << 'EOF'
ECS_CLUSTER=${cluster_name}
ECS_AVAILABLE_LOGGING_DRIVERS=["json-file","awslogs"]
ECS_ENABLE_TASK_IAM_ROLE=true
ECS_ENABLE_CONTAINER_METADATA=true
ECS_CONTAINER_START_TIMEOUT=60m
ECS_CONTAINER_CREATE_TIMEOUT=60m
ECS_MANIFEST_PULL_TIMEOUT=60m
ECS_IMAGE_PULL_BEHAVIOR=default
ECS_DISABLE_IMAGE_CLEANUP=false
ECS_RESERVED_MEMORY=256
ECS_LOGLEVEL=info
ECS_ENABLE_SPOT_INSTANCE_DRAINING=true
ECS_ENABLE_TASK_ENI=true
ECS_ENABLE_CONTAINER_METADATA_V4=true
EOF


mkdir -p /etc/docker
cat > /etc/docker/daemon.json << 'EOF'
{
  "max-concurrent-downloads": 3,
  "max-concurrent-uploads": 3,
  "live-restore": true,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "default-runtime": "runc"
}
EOF

systemctl enable docker || echo "Warning: Failed to enable docker"
timeout 30 systemctl start docker || echo "Warning: Docker start timed out"

sleep 3

if timeout 10 systemctl is-active --quiet docker; then
    echo "Docker service is running"
else
    echo "Docker service is not running"
fi

set -e
cd /tmp
curl -sSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip || {
    echo "CRITICAL: Failed to download AWS CLI"
    exit 1
}
unzip -q awscliv2.zip || {
    echo "CRITICAL: Failed to unzip AWS CLI"
    exit 1
}
./aws/install --update || {
    echo "CRITICAL: Failed to install AWS CLI"
    exit 1
}

# Check if AWS CLI was installed by the installer
if [ -f "/usr/local/aws-cli/v2/current/bin/aws" ]; then
    echo "AWS CLI found at /usr/local/aws-cli/v2/current/bin/aws"
    AWS_CLI_PATH="/usr/local/aws-cli/v2/current/bin/aws"
elif [ -f "/usr/bin/aws" ]; then
    echo "AWS CLI found at /usr/bin/aws"
    AWS_CLI_PATH="/usr/bin/aws"
elif command -v aws >/dev/null 2>&1; then
    echo "AWS CLI found in PATH: $(which aws)"
    AWS_CLI_PATH="$(which aws)"
else
    echo "Aws cli not found anywhere"
    exit 1
fi

# Create symlinks to ensure it's available at both expected paths
ln -sf "$AWS_CLI_PATH" /usr/bin/aws 2>/dev/null || echo "Warning: Could not create /usr/bin/aws symlink"
ln -sf "$AWS_CLI_PATH" /usr/local/bin/aws 2>/dev/null || echo "Warning: Could not create /usr/local/bin/aws symlink"


curl -sSL https://install.tracer.cloud | sh -s user_319lEu0yJcTWaTWl1X6TzC6NyG6

tracer init --user-id user_319lEu0yJcTWaTWl1X6TzC6NyG6 \
    --pipeline-name aws_batch_rnaseq \
    --pipeline-type RNA-SEQ \
    --environment aws-batch \
    --watch-dir="/var/log"

systemctl stop firewalld || true
systemctl disable firewalld || true
iptables -F || true
iptables -P INPUT ACCEPT || true
iptables -P FORWARD ACCEPT || true
iptables -P OUTPUT ACCEPT || true
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_keepalive_time = 600' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_keepalive_probes = 9' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_keepalive_intvl = 75' >> /etc/sysctl.conf
sysctl -p

# Allow loopback traffic for tracer
iptables -A INPUT -i lo -j ACCEPT || true
iptables -A OUTPUT -o lo -j ACCEPT || true

echo "Network configuration completed"

# Test connectivity
echo "Testing connectivity..."
curl -s http://169.254.169.254/latest/meta-data/instance-id && echo "Metadata service accessible"
curl -s https://www.google.com > /dev/null && echo "Internet connectivity working" || echo "No internet connectivity"


# Start ECS service
{
    echo "ECS startup process starting..."
    
    # Wait for Docker to be fully ready
    echo "Waiting for Docker to be ready..."
    for i in {1..30}; do
        if docker info > /dev/null 2>&1; then
            echo "Docker is ready after $i attempts"
            break
        fi
        echo "Waiting for Docker... ($i/30)"
        sleep 2
    done
    
    echo "Running ECS startup sequence..."
    
    # Kill any existing ECS processes
    pkill -f ecs-agent 2>/dev/null || true
    pkill -f "systemctl.*ecs" 2>/dev/null || true
    
    # Reload systemd daemon
    systemctl daemon-reload 2>/dev/null || true
    
    # Reset failed state
    systemctl reset-failed ecs 2>/dev/null || true
    
    # Start ECS service
    systemctl start ecs 2>/dev/null || {
        echo "First ECS start attempt failed, trying again..."
        sleep 2
        systemctl start ecs 2>/dev/null || true
    }
    
    # Final status check
    sleep 3
    if systemctl is-active --quiet ecs 2>/dev/null; then
        echo "ECS service is running successfully"
    else
        echo "ECS service not active, but it will continue trying"
    fi
    
} > /var/log/ecs-startup.log 2>&1 &

echo "ECS startup initiated in background"
echo "Check /var/log/ecs-startup.log for ECS startup details"


echo "Docker status: $(timeout 5 systemctl is-active docker 2>/dev/null || echo 'timeout/inactive')"
echo "  - Version: $(timeout 5 docker --version 2>/dev/null || echo 'Docker not accessible')"
echo "ECS status: $(timeout 5 systemctl is-active ecs 2>/dev/null || echo 'starting/inactive - check /var/log/ecs-startup.log')"
echo "Instance IP: $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
echo "Setup completed at: $(date)"
echo "Log files:"
echo "  - User data: /var/log/user-data.log"
echo "  - Script log: /var/log/tracer/script.log"
echo "=== Bootstrap Complete ==="

--==MYBOUNDARY==--

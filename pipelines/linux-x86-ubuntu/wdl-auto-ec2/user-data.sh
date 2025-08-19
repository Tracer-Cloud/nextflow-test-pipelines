#!/bin/bash
set -eux

exec > /var/log/user-data.log 2>&1

# Update system and install dependencies
apt-get update -y
apt-get install -y default-jre git wget curl

# Install Tracer first
curl -sSL https://install.tracer.cloud | sh -s user_2y5dYWwh7RlZWKDOPl7E0LeQGh1

# Initialize Tracer
sudo tracer init

# Install Pixi package manager
curl -fsSL https://pixi.sh/install.sh | bash
export PATH="$HOME/.pixi/bin:$PATH"

# Clone the repository containing WDL workflows
git clone https://github.com/Tracer-Cloud/nextflow-test-pipelines.git /home/ubuntu/workflows
chown -R ubuntu:ubuntu /home/ubuntu/workflows

# Navigate to the WDL directory
cd /home/ubuntu/workflows/pipelines/shared/wdl

# Set ownership for ubuntu user
chown -R ubuntu:ubuntu /home/ubuntu/workflows

# Run the WDL pipeline as ubuntu user
sudo -u ubuntu bash -c "
    export PATH=\"/home/ubuntu/.pixi/bin:\$PATH\"
    cd /home/ubuntu/workflows/pipelines/shared/wdl
    
    # Install dependencies and run the pipeline
    pixi run script
"

echo 'WDL pipeline execution completed' > /var/log/wdl-completion.log

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

# Demo tracer WDL
sudo tracer demo wdl && shutdown -h +20 "Auto-shutdown after 20 minutes as configured"
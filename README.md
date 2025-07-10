[![Linux aarch64 Ubuntu](https://img.shields.io/github/actions/workflow/status/Tracer-Cloud/nextflow-test-pipelines/linux-aarch64-ubuntu.yml?branch=main&label=linux-aarch64-ubuntu&logo=linux)](https://github.com/Tracer-Cloud/nextflow-test-pipelines/actions/workflows/linux-aarch64-ubuntu.yml) [![Linux x86_64 Ubuntu](https://img.shields.io/github/actions/workflow/status/Tracer-Cloud/nextflow-test-pipelines/linux-x86_64-ubuntu.yml?branch=main&label=linux-x86_64-ubuntu&logo=linux)](https://github.com/Tracer-Cloud/nextflow-test-pipelines/actions/workflows/linux-x86_64-ubuntu.yml) [![Linux aarch64 Amazon Linux](https://img.shields.io/github/actions/workflow/status/Tracer-Cloud/nextflow-test-pipelines/linux-aarch64-amazon-lin.yml?branch=main&label=linux-aarch64-amazon&logo=linux)](https://github.com/Tracer-Cloud/nextflow-test-pipelines/actions/workflows/linux-aarch64-amazon-lin.yml) [![Linux x86_64 Amazon Linux](https://img.shields.io/github/actions/workflow/status/Tracer-Cloud/nextflow-test-pipelines/linux-x86-amazon-lin.yml?branch=main&label=linux-x86_64-amazon&logo=linux)](https://github.com/Tracer-Cloud/nextflow-test-pipelines/actions/workflows/linux-x86-amazon-lin.yml) [![macOS ARM64](https://img.shields.io/github/actions/workflow/status/Tracer-Cloud/nextflow-test-pipelines/macos-arm64.yml?branch=main&label=macos-arm64&logo=apple)](https://github.com/Tracer-Cloud/nextflow-test-pipelines/actions/workflows/macos-arm64.yml) [![macOS Intel x86](https://img.shields.io/github/actions/workflow/status/Tracer-Cloud/nextflow-test-pipelines/macos-intel-x86.yml?branch=main&label=macos-intel-x86&logo=apple)](https://github.com/Tracer-Cloud/nextflow-test-pipelines/actions/workflows/macos-intel-x86.yml) [![Codespaces](https://img.shields.io/github/actions/workflow/status/Tracer-Cloud/nextflow-test-pipelines/codespaces.yml?branch=main&label=codespaces&logo=github)](https://github.com/Tracer-Cloud/nextflow-test-pipelines/actions/workflows/codespaces.yml)


[![Docker Image](https://img.shields.io/docker/pulls/tracercloud/tracer?logo=docker&logoColor=white)](https://hub.docker.com/r/tracercloud/tracer) [![CI Status](https://img.shields.io/github/actions/workflow/status/Tracer-Cloud/nextflow-test-pipelines/docker-build-push.yml?branch=main&label=docker-build&logo=docker)](https://github.com/Tracer-Cloud/nextflow-test-pipelines/actions/workflows/docker-build-push.yml) [![Latest Binary Release](https://img.shields.io/github/v/release/Tracer-Cloud/tracer-client?logo=github&logoColor=white)](https://github.com/Tracer-Cloud/tracer-client/releases)


# Reliable Nextflow Pipelines with Tracer Observability

- Reliable Nextflow pipelines: Fully-tested examples that run seamlessly across all environments

- Automated CI/CD: Regularly validated pipelines guarantee consistent functionality

- Easy Installation: Simplified, automated installation scripts for quick setup

- Fast Community Support: Open an issue for assistance, someone will try to get back to you within 24 hours

- GitHub Codespaces Compatible: Effortlessly run examples directly in Codespaces 



## Quickstart Tracer Sandbox

Get started instantly by visiting [sandbox.tracer.cloud](https://sandbox.tracer.cloud/).

## Getting Started

### 1. Install Tracer

Install Tracer on your operating system (one-time installation):

```bash
curl -sSL https://install.tracer.cloud | sh && source ~/.bashrc && source ~/.zshrc
```

### 2. Navigate to the correct git file

Select your preferred tool for managing software environments and dependencies


Pixi: 
```bash
cd /workspaces/nextflow-test-pipelines/pipelines/codespaces/nextflow-pixi
```

Conda:
```bash
cd /workspaces/nextflow-test-pipelines/pipelines/codespaces/nextflow-conda
```

### 3. Initialize Tracer

Launch Tracer by running: (Root privileges required)

```bash
tracer init
```

### 4. Run pipeline
We have pre-installed some pipelines in the Codespaces for you to run.

We would recommend to start with a simple rnaseq pipeline in Nextflow:
```bash
./run.sh
```
Other pipelines, written in Bash, Nextflow, WDL, and CWL can be found under the pipelines files

Play around with the other pipelines, have fun!


## Monitor your Pipeline

Track your pipeline's progress through the Tracer monitoring dashboard, accessible via the 'Open Grafana Dashboard' button in the Onboarding.

The dashboard provides real-time insights into:

- Execution metrics
- Pipeline stages
- Status updates

## What Is Tracer and Why Use It?

Tracer is a cutting-edge system-level observability platform specifically designed for scientific computing. It combines advanced technology with deep industry knowledge to provide comprehensive insights into performance and costs. With its simple one-line Linux agent installation and intuitive dashboards, Tracer delivers immediate visibility into scientific computing environments.

Unlike general-purpose monitoring tools, Tracer is purpose-built for scientific pipelines, offering clear visibility into pipeline stages and execution runs. This is particularly valuable in environments like AWS Batch, where tracking processes across containers can be challenging and failed container logs are often lost.

Tracer excels by:

- Intelligently organizing and labeling pipelines, execution runs, and steps
- Running directly on Linux without requiring code modifications
- Supporting any programming language
- Enabling seamless integration across diverse IT environments (AlphaFold, Slurm, Airflow, Nextflow, and local Bash scripts)

Built with enterprise security in mind, Tracer ensures your data never leaves your infrastructure - a key advantage over solutions like DataDog.

## Key Features

Optimize your pipelines with powerful metrics:

- Time and cost per dataset processed
- Execution duration and bottleneck identification for each pipeline step
- Cost attribution across pipelines, teams, and environments (dev, CI/CD, prod)

These insights help make sense of complex scientific toolchains that traditionally lack proper observability.

## Mission

> "_The goal of Tracer's Rust agent is to equip scientists and engineers with DevOps intelligence to efficiently harness massive computational power for humanity's most critical challenges._"

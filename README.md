<h1 align="center" style="border-bottom: none">
    <a href="https://tracer.cloud" target="_blank"><img alt="Tracer" src="https://github.com/user-attachments/assets/5bbbdcee-11ca-4f09-b042-a5259309b7e4"></a><br>Tracer
</h1>

<p align="center">Try out <a href="https://sandbox.tracer.cloud" target="_blank">tracer.cloud</a> in the sandbox enviroment.</p>

[![Linux aarch64 Ubuntu](https://img.shields.io/github/actions/workflow/status/Tracer-Cloud/nextflow-test-pipelines/linux-aarch64-ubuntu.yml?branch=main&label=linux-aarch64-ubuntu&logo=linux)](https://github.com/Tracer-Cloud/nextflow-test-pipelines/actions/workflows/linux-aarch64-ubuntu.yml) [![Linux x86_64 Ubuntu](https://img.shields.io/github/actions/workflow/status/Tracer-Cloud/nextflow-test-pipelines/linux-x86_64-ubuntu.yml?branch=main&label=linux-x86_64-ubuntu&logo=linux)](https://github.com/Tracer-Cloud/nextflow-test-pipelines/actions/workflows/linux-x86_64-ubuntu.yml) [![Linux aarch64 Amazon Linux](https://img.shields.io/github/actions/workflow/status/Tracer-Cloud/nextflow-test-pipelines/linux-aarch64-amazon-lin.yml?branch=main&label=linux-aarch64-amazon&logo=linux)](https://github.com/Tracer-Cloud/nextflow-test-pipelines/actions/workflows/linux-aarch64-amazon-lin.yml) [![Linux x86_64 Amazon Linux](https://img.shields.io/github/actions/workflow/status/Tracer-Cloud/nextflow-test-pipelines/linux-x86-amazon-lin.yml?branch=main&label=linux-x86_64-amazon&logo=linux)](https://github.com/Tracer-Cloud/nextflow-test-pipelines/actions/workflows/linux-x86-amazon-lin.yml) [![macOS ARM64](https://img.shields.io/github/actions/workflow/status/Tracer-Cloud/nextflow-test-pipelines/macos-arm64.yml?branch=main&label=macos-arm64&logo=apple)](https://github.com/Tracer-Cloud/nextflow-test-pipelines/actions/workflows/macos-arm64.yml) [![macOS Intel x86](https://img.shields.io/github/actions/workflow/status/Tracer-Cloud/nextflow-test-pipelines/macos-intel-x86.yml?branch=main&label=macos-intel-x86&logo=apple)](https://github.com/Tracer-Cloud/nextflow-test-pipelines/actions/workflows/macos-intel-x86.yml) [![Codespaces](https://img.shields.io/github/actions/workflow/status/Tracer-Cloud/nextflow-test-pipelines/codespaces.yml?branch=main&label=codespaces&logo=github)](https://github.com/Tracer-Cloud/nextflow-test-pipelines/actions/workflows/codespaces.yml)

[![Docker Image](https://img.shields.io/docker/pulls/tracercloud/tracer?logo=docker&logoColor=white)](https://hub.docker.com/r/tracercloud/tracer) [![CI Status](https://img.shields.io/github/actions/workflow/status/Tracer-Cloud/nextflow-test-pipelines/docker-build-push.yml?branch=main&label=docker-build&logo=docker)](https://github.com/Tracer-Cloud/nextflow-test-pipelines/actions/workflows/docker-build-push.yml) [![Latest Binary Release](https://img.shields.io/github/v/release/Tracer-Cloud/tracer-client?logo=github&logoColor=white)](https://github.com/Tracer-Cloud/tracer-client/releases)

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/Tracer-Cloud/nextflow-test-pipelines/tree/main/pipelines/codespaces)

# Reliable Nextflow Pipelines with Tracer Observability

Tracer is a system-level monitoring platform purpose-built for scientific computing. It is a a one-line install Linux agent and instant dashboards to give you insights into pipeline performance and cost optimization.
Observability for Scientific HPC Workloads

Use the tracer client https://github.com/Tracer-Cloud/tracer-client

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

**Note: Root privileges required**

```bash
curl -sSL https://install.tracer.cloud | sh && source ~/.bashrc && source ~/.zshrc
```

### 2. Run a Pipeline: Initialize the Tracer Client

Launch a monitoring pipeline by running:

**Note: Root privileges required**

```bash
tracer init
```

### 3. Run pipeline

You can test your pipelines using tracer, or use our pipelines to test out tracer, we recommend following the sandbox for a smoother onboarding experience, you can find a list of the supported OS here:

- [Codespaces](./pipelines/codespaces/)

- [Linux x86_64](./pipelines/)

  - [Ubuntu](./pipelines/linux-x86-ubuntu/)
  - [Amazon Linux](./pipelines/linux-arm-amazon-linux/)

- [Linux aarch64](./pipelines/)

  - [Ubuntu](./pipelines/linux-arm-ubuntu/)
  - [Amazon Linux](./pipelines/linux-arm-amazon-linux/)

- [macOS](./pipelines/)

  - [Apple Silicon / arm64](./pipelines/macos-arm64/)
  - [Apple Intel / x86](./pipelines/macos-intel-x86/)

- [AWS Batch](./pipelines/aws-batch/)

We have provided a varioety of examples based on your computation power, written in Bash, Python, Nextflow, WDL and CWL.

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

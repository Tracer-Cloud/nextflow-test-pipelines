<h1 align="center" style="border-bottom: none">
    <a href="https://tracer.cloud" target="_blank"><img alt="Tracer" src="https://github.com/user-attachments/assets/5bbbdcee-11ca-4f09-b042-a5259309b7e4"></a><br>Reliable Nextflow Pipelines with Tracer Observability
</h1>

<br><br>

<p align="center">
  <img 
    src="https://github.com/user-attachments/assets/1cd1f0ba-e646-4291-aa10-0a0235b804bb" 
    alt="Tracer_HighLevelOverview" 
    width="603" 
    height="348" 
  />
</p>
<br><br>

<p align="center"><b>Try <a href="https://sandbox.tracer.cloud" target="_blank">tracer.cloud</a> instantly in the sandbox environment.</b></p>

<p align="center">
  <a href="https://github.com/Tracer-Cloud/nextflow-test-pipelines/actions/workflows/linux-aarch64-ubuntu.yml"><img alt="Linux aarch64 Ubuntu" src="https://img.shields.io/github/actions/workflow/status/Tracer-Cloud/nextflow-test-pipelines/linux-aarch64-ubuntu.yml?branch=main&label=linux-aarch64-ubuntu&logo=linux"></a>
  <a href="https://github.com/Tracer-Cloud/nextflow-test-pipelines/actions/workflows/linux-x86_64-ubuntu.yml"><img alt="Linux x86_64 Ubuntu" src="https://img.shields.io/github/actions/workflow/status/Tracer-Cloud/nextflow-test-pipelines/linux-x86_64-ubuntu.yml?branch=main&label=linux-x86_64-ubuntu&logo=linux"></a>
  <a href="https://github.com/Tracer-Cloud/nextflow-test-pipelines/actions/workflows/linux-aarch64-amazon-lin.yml"><img alt="Linux aarch64 Amazon Linux" src="https://img.shields.io/github/actions/workflow/status/Tracer-Cloud/nextflow-test-pipelines/linux-aarch64-amazon-lin.yml?branch=main&label=linux-aarch64-amazon&logo=linux"></a>
  <a href="https://github.com/Tracer-Cloud/nextflow-test-pipelines/actions/workflows/linux-x86-amazon-lin.yml"><img alt="Linux x86_64 Amazon Linux" src="https://img.shields.io/github/actions/workflow/status/Tracer-Cloud/nextflow-test-pipelines/linux-x86-amazon-lin.yml?branch=main&label=linux-x86_64-amazon&logo=linux"></a>
  <a href="https://github.com/Tracer-Cloud/nextflow-test-pipelines/actions/workflows/macos-arm64.yml"><img alt="macOS ARM64" src="https://img.shields.io/github/actions/workflow/status/Tracer-Cloud/nextflow-test-pipelines/macos-arm64.yml?branch=main&label=macos-arm64&logo=apple"></a>
  <a href="https://github.com/Tracer-Cloud/nextflow-test-pipelines/actions/workflows/macos-intel-x86.yml"><img alt="macOS Intel x86" src="https://img.shields.io/github/actions/workflow/status/Tracer-Cloud/nextflow-test-pipelines/macos-intel-x86.yml?branch=main&label=macos-intel-x86&logo=apple"></a>
  <a href="https://github.com/Tracer-Cloud/nextflow-test-pipelines/actions/workflows/codespaces.yml"><img alt="Codespaces" src="https://img.shields.io/github/actions/workflow/status/Tracer-Cloud/nextflow-test-pipelines/codespaces.yml?branch=main&label=codespaces&logo=github"></a>
</p>

<p align="center">
  <a href="https://hub.docker.com/r/tracercloud/tracer"><img alt="Docker Image" src="https://img.shields.io/docker/pulls/tracercloud/tracer?logo=docker&logoColor=white"></a>
  <a href="https://github.com/Tracer-Cloud/nextflow-test-pipelines/actions/workflows/docker-build-push.yml"><img alt="CI Status" src="https://img.shields.io/github/actions/workflow/status/Tracer-Cloud/nextflow-test-pipelines/docker-build-push.yml?branch=main&label=docker-build&logo=docker"></a>
  <a href="https://github.com/Tracer-Cloud/tracer-client/releases"><img alt="Latest Binary Release" src="https://img.shields.io/github/v/release/Tracer-Cloud/tracer-client?logo=github&logoColor=white"></a>
</p>

<p align="center">
  <a href="https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=920248651&machine=largePremiumLinux"><img alt="Open in GitHub Codespaces" src="https://github.com/codespaces/badge.svg"></a>
</p>

---

Tracer is a system-level observability platform purpose-built for scientific computing. With a one-line Linux client install and instant dashboards, Tracer gives you deep insights into pipeline performance and cost optimization.

---

## Why Tracer?

- **Reliable Nextflow pipelines:** Fully-tested examples that run seamlessly across all environments
- **Automated CI/CD:** Regularly validated pipelines for consistent functionality
- **Easy Installation:** Automated scripts for quick setup
- **Fast Community Support:** Open an issue and get a response within 24 hours
- **GitHub Codespaces Compatible:** Run examples directly in Codespaces

## Quickstart (Sandbox)

Get started instantly:

1. **Visit the [Tracer Sandbox](https://sandbox.tracer.cloud/)**
2. Follow the onboarding instructions to launch your first monitored pipeline

---

## Getting Started

### 1. Install Tracer

Install Tracer on your system (one-time setup):

> **Note:** Root privileges required

```bash
curl -sSL https://install.tracer.cloud | sh
```

### 2. Initialize the Tracer Client (requires token)

Start the Tracer client to initialize a pipeline and enable monitoring. You must provide your Tracer token every time you initialize.

- Get your token from the [Tracer Sandbox](https://sandbox.tracer.cloud/)
- Then run:

> **Note:** Root privileges required

```bash
sudo tracer init --token <paste-your-token-here> --watch-dir "/tmp/tracer"
```

### 3. Run a Pipeline

You can use your own pipelines or try our ready-to-run examples. For the smoothest onboarding, follow the sandbox instructions or pick a pipeline for your OS below:

- **[Codespaces](./pipelines/codespaces/)**
- **[Linux x86_64](./pipelines/)**
  - [Ubuntu](./pipelines/linux-x86-ubuntu/)
  - [Amazon Linux](./pipelines/linux-arm-amazon-linux/)
- **[Linux aarch64](./pipelines/)**
  - [Ubuntu](./pipelines/linux-arm-ubuntu/)
  - [Amazon Linux](./pipelines/linux-arm-amazon-linux/)
- **[macOS](./pipelines/)**
  - [Apple Silicon / arm64](./pipelines/macos-arm64/)
  - [Apple Intel / x86](./pipelines/macos-intel-x86/)
- **[AWS Batch](./pipelines/aws-batch/)**

We provide a variety of examples for different compute environments, written in Bash, Python, Nextflow, WDL, and CWL.

**Recommended:** Start with a simple Nextflow fastquorum pipeline.

---

## Monitor Your Pipeline

Track your pipeline's progress in real time via the Tracer dashboard. Access it through the 'Open Grafana Dashboard' button during onboarding.

The dashboard provides:

- Execution metrics
- Pipeline stages
- Status updates

---

## What Makes Tracer Different?

Tracer is a cutting-edge observability platform designed for scientific computing. Unlike general-purpose monitoring tools, Tracer is purpose-built for scientific pipelines, offering:

- Intelligent organization and labeling of pipelines, runs, and steps
- Zero code changes: runs directly on Linux
- Support for any programming language
- Seamless integration with diverse environments (AlphaFold, Slurm, Airflow, Nextflow, Bash, and more)
- Enterprise-grade security: your data never leaves your infrastructure

This is especially valuable for environments like AWS Batch, where tracking processes across containers is challenging and logs can be lost.

---

## Key Features

- Time and cost per dataset processed
- Step-level execution duration and bottleneck identification
- Cost attribution across pipelines, teams, and environments (dev, CI/CD, prod)

These insights help you optimize complex scientific toolchains that traditionally lack proper observability.

---

## Mission

> "_The goal of Tracer's Rust client is to equip scientists and engineers with DevOps intelligence to efficiently harness massive computational power for humanity's most critical challenges._"

---

For more details, see the [tracer client](https://github.com/Tracer-Cloud/tracer-client) and our [website](https://tracer.cloud).

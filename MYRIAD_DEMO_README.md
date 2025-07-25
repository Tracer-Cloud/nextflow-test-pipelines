# Myriad Demo Instructions

## AWS Instance Setup

### Instance Configuration
- **Instance Type**: `c7a.4xlarge`
- **Disk Space**: 200GB (to be sure)

## Demo Steps

### 1. Initial Setup

Login as root:
```bash
sudo su
```

Install Tracer:
```bash
curl -sSL https://install.tracer.cloud | sh
```

Initialize Tracer:
```bash
tracer init
```

### 2. Running the WDL Pipeline

Navigate to the pipeline directory:
```bash
cd /nextflow-test-pipelines/pipelines/linux-x86-ubuntu/wdl
```

Run the pipeline:
```bash
./run.sh
```


### WDL Pipeline Demo Sandbox
[View Demo Results](https://sandbox.tracer.cloud/run-overview/demo_pipeline/snowy-leopard-590)





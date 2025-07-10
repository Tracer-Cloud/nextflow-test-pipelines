# Airflow Testing Documentation for Tracer

This documentation provides step-by-step instructions for running and testing Airflow workflows with Tracer in different environments.

## Table of Contents
- [Setting Up and Running Airflow](#setting-up-and-running-airflow)
- [Running Tracer](#running-tracer)
- [Docker Container Management](#docker-container-management)
- [Troubleshooting and Debugging](#troubleshooting-and-debugging)
- [Airflow Web Interface](#airflow-web-interface)
- [GitHub Codespaces Integration](#github-codespaces-integration)
- [Bioinformatics Docker Images](#bioinformatics-docker-images)

## Setting Up and Running Airflow

### Starting Airflow Services
1. Start all required Airflow services using docker compose:
```bash
sudo docker compose up -d
```

## Running Tracer
1. Export required AWS credentials to your environment:
```bash
#!/bin/bash
export AWS_ACCESS_KEY_ID=XXXXXXX
export AWS_SECRET_ACCESS_KEY=XXXXXXXX
export AWS_LOG_LEVEL="debug"

echo "AWS environment variables exported."
```

2. Install Tracer 
```bash
curl -sSL https://install.tracer.cloud | sh && source ~/.bashrc && source ~/.zshrc
```

3. Run the tracer initialization command:
```bash
   tracer init --pipeline-name airflow_vin --environment sandbox_test --user-operator vincent --pipeline-type rnaseq
```

## Run Sysdig as backup to see if events are tracked 
1. Install Sysdig
```bash
curl -s https://s3.amazonaws.com/download.draios.com/stable/install-sysdig | sudo bash
```

2. Filter events for the current Airflow pipeline
```bash
# Alternative: #sudo sysdig "proc.name=fastqc or proc.name=hisat2 or proc.name=STAR"
sudo sysdig "evt.type=execve and (proc.name=fastqc or proc.name=hisat2 or proc.name=STAR)"
```


### Managing Pipelines
1. Unpause the RNA-seq pipeline located in `/dags/rnaseq_pipeline.py`:
```bash
sudo docker compose run --rm airflow-cli dags unpause pipeline_rnaseq
```

2. Trigger the pipeline with a custom run ID:
```bash
sudo docker compose run --rm airflow-cli dags trigger pipeline_rnaseq --run-id=my_custom_run_001
```

3. Check the status of a specific pipeline run:
```bash
sudo docker compose run --rm airflow-cli tasks states-for-dag-run pipeline_rnaseq my_custom_run_001
```

4. List all runs for a specific DAG:
```bash
sudo docker compose run --rm airflow-cli dags list-runs --dag-id pipeline_rnaseq
```

5. Check the current state of a DAG:
```bash
sudo docker compose run --rm airflow-cli dags state pipeline_rnaseq
```

6. Delete a DAG (including its history and metadata):
```bash
sudo docker compose run --rm airflow-cli airflow dags delete pipeline_rnaseq
```

## Docker Container Management

### Container Status and Management
1. View running Docker processes:
```bash
sudo docker compose ps
```

2. Verify container images in use:
```bash
sudo docker ps --format "table {{.Names}}\t{{.Image}}"
```

3. Restart containers after code changes:
```bash
sudo docker compose restart
```

4. View logs from a specific container:
```bash
sudo docker logs -f airflow-airflow-worker-1
```

### Clean Up
1. Stop all containers and remove volumes:
```bash
sudo docker compose down --volumes --remove-orphans
```

2. Remove logs:
```bash
rm -rf logs/*
```

## Troubleshooting and Debugging

### Accessing Container Environments
1. Access the bash environment inside the Airflow worker container:
```bash
sudo docker exec -u 0 -it airflow-airflow-worker-1 /bin/bash
```
*Note: Type "exit" to exit the container shell*

2. Execute a Python script inside the container:
```bash
sudo docker exec -it airflow-airflow-worker-1 python /opt/airflow/dags/pipeline_rnaseq.py
```

## Airflow Web Interface

The Airflow web UI is accessible at:
- URL: http://127.0.0.1:8080/login/
- Username: `airflow`
- Password: `airflow`

## GitHub Codespaces Integration

## Bioinformatics Docker Images

### Required Tool Images

1. **HISAT2** - RNA sequence alignment tool:
```bash
sudo docker pull quay.io/biocontainers/hisat2:2.2.1--h503566f_8
```

2. **STAR** - Spliced Transcripts Alignment to a Reference:
```bash
sudo docker pull quay.io/biocontainers/star:2.7.3a--h5ca1c30_1
```

3. **FastQC** - Quality control tool for high throughput sequence data:
```bash
sudo docker pull quay.io/biocontainers/fastqc:0.11.7--pl5.22.0_2
```

### Note on Celery Worker Configuration
When using Celery executor with Airflow, the worker configuration is managed via docker-compose. Refer to the docker-compose file for specifics on worker settings.
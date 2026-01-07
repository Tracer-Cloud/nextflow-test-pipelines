from datetime import datetime
from airflow import DAG
from airflow.providers.docker.operators.docker import DockerOperator
from airflow.operators.python import PythonOperator
import logging

# Default arguments for the DAG
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'retries': 0
}

# Logging function
def log_message(message):
    logging.info(f"RNA-seq Pipeline: {message}")

# Define the DAG
with DAG(
    dag_id='pipeline_rnaseq',
    default_args=default_args,
    description='RNA-seq analysis using separate Docker containers per tool',
    schedule=None,  # Manual trigger only
    start_date=datetime(2025, 1, 1),
    catchup=False,
    tags=['rnaseq'],
) as dag:

    start_log = PythonOperator(
        task_id='start_log',
        python_callable=log_message,
        op_kwargs={'message': 'Pipeline started'},
    )

    fastqc_version = DockerOperator(
        task_id='fastqc_version',
        image='quay.io/biocontainers/fastqc:0.11.7--pl5.22.0_2',
        api_version='auto',
        auto_remove=True,
        command='fastqc --version',
        docker_url='unix://var/run/docker.sock',
        network_mode='bridge'
    )

    star_version = DockerOperator(
        task_id='star_version',
        image='quay.io/biocontainers/star:2.7.3a--h5ca1c30_1',
        api_version='auto',
        auto_remove=True,
        command='STAR --version',
        docker_url='unix://var/run/docker.sock',
        network_mode='bridge'
    )

    hisat2_version = DockerOperator(
        task_id='hisat2_version',
        image='quay.io/biocontainers/hisat2:2.2.1--h503566f_8',
        api_version='auto',
        auto_remove=True,
        command='hisat2 --version',
        docker_url='unix://var/run/docker.sock',
        network_mode='bridge'
    )

    end_log = PythonOperator(
        task_id='end_log',
        python_callable=log_message,
        op_kwargs={'message': 'Pipeline completed'},
    )

    # Define task order
    start_log >> [fastqc_version, star_version, hisat2_version] >> end_log

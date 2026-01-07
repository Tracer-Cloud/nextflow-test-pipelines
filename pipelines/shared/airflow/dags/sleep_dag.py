import time

from airflow import DAG 
from airflow.decorators import task
from airflow.utils.timezone import datetime
from datetime import timedelta
from random import randint, choice


@task
def task1():
    time.sleep(randint(1, 100))
    if choice([True, False]):
        raise Exception


with DAG(
    dag_id='sleep_random',
    start_date=datetime(2024, 11, 2),
    schedule=timedelta(minutes=4),
    catchup=False
) as dag:

    task1()
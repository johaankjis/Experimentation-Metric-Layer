"""
Airflow DAG for Weekly Experiment Reporting
Automatically computes experiment results and publishes to warehouse
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash_operator import BashOperator
from airflow.operators.python_operator import PythonOperator
from airflow.providers.slack.operators.slack_webhook import SlackWebhookOperator

default_args = {
    'owner': 'data-science',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email': ['data-science@company.com'],
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'experiment_reporting_weekly',
    default_args=default_args,
    description='Weekly experiment readout generation',
    schedule_interval='0 9 * * 1',  # Every Monday at 9 AM
    catchup=False,
    tags=['experiments', 'reporting'],
)

# Task 1: Run dbt models to refresh metrics
refresh_metrics = BashOperator(
    task_id='refresh_metrics',
    bash_command="""
        cd /path/to/dbt_project && \
        dbt run --models tag:metrics
    """,
    dag=dag,
)

# Task 2: Run experiment analysis
run_experiment_analysis = BashOperator(
    task_id='run_experiment_analysis',
    bash_command="""
        cd /path/to/dbt_project && \
        dbt run --models tag:experiments
    """,
    dag=dag,
)

# Task 3: Run data quality tests
run_quality_tests = BashOperator(
    task_id='run_quality_tests',
    bash_command="""
        cd /path/to/dbt_project && \
        dbt test --models tag:metrics tag:experiments
    """,
    dag=dag,
)

# Task 4: Generate experiment readouts
def generate_experiment_readouts(**context):
    """
    Generate experiment readouts for all active experiments
    This would connect to your data warehouse and run experiment templates
    """
    import pandas as pd
    from presto import Presto  # Hypothetical Presto client
    
    # Query for active experiments
    query = """
    SELECT experiment_id, experiment_name, target_metric
    FROM experimentation.experiment_registry
    WHERE status = 'running'
    """
    
    # For each active experiment, run analysis templates
    # This is a simplified example
    experiments = [
        {'id': 'exp_001', 'metric': 'fact_dau'},
        {'id': 'exp_002', 'metric': 'fact_activation'},
    ]
    
    results = []
    for exp in experiments:
        # Run difference-in-means test
        result_query = f"""
        WITH variants AS (
            SELECT e.experiment_id, e.variant, m.metric_value
            FROM experimentation.experiment_assignments e
            JOIN experimentation.{exp['metric']} m ON e.user_id = m.user_id
            WHERE e.experiment_id = '{exp['id']}'
        )
        SELECT 
            variant,
            AVG(metric_value) as mean_value,
            COUNT(*) as n
        FROM variants
        GROUP BY variant
        """
        results.append({'experiment': exp['id'], 'status': 'computed'})
    
    return results

generate_readouts = PythonOperator(
    task_id='generate_readouts',
    python_callable=generate_experiment_readouts,
    dag=dag,
)

# Task 5: Notify completion
notify_slack = SlackWebhookOperator(
    task_id='notify_slack',
    http_conn_id='slack_webhook',
    message="""
    ✅ Weekly Experiment Reporting Completed
    
    - Metrics refreshed
    - Experiment analysis computed
    - Quality tests passed
    - Readouts generated
    
    View results in Tableau dashboard
    """,
    channel='#data-science',
    dag=dag,
)

# Define task dependencies
refresh_metrics >> run_experiment_analysis >> run_quality_tests >> generate_readouts >> notify_slack

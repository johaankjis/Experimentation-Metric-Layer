# Setup Guide

## Prerequisites

- Presto/Trino database access
- dbt installed (`pip install dbt-trino`)
- Airflow for orchestration (optional)
- Access to raw event data tables

## Installation

### 1. Configure dbt Profile

Edit `dbt_project/profiles.yml` with your Trino/Presto connection details:

```yaml
experimentation:
  target: dev
  outputs:
    dev:
      type: trino
      method: none
      host: your-trino-host.com
      port: 8080
      catalog: hive
      schema: experimentation_dev
      threads: 4
```

### 2. Set Up Source Tables

Ensure you have the following source tables in your data warehouse:

- `raw.events` - Raw event stream data
- `raw.users` - User dimension table
- `raw.experiment_assignments` - Experiment variant assignments
- `raw.experiments` - Experiment metadata

### 3. Run dbt Models

```bash
cd dbt_project

# Install dependencies (if using dbt packages)
dbt deps

# Run all models
dbt run

# Run tests
dbt test

# Generate documentation
dbt docs generate
dbt docs serve
```

### 4. Validate Metrics

Check that canonical metrics are populated:

```sql
-- Check DAU
SELECT activity_date, COUNT(DISTINCT user_id) as dau
FROM experimentation.fact_dau
GROUP BY 1
ORDER BY 1 DESC
LIMIT 7;

-- Check activation rate
SELECT 
    AVG(is_activated) as activation_rate,
    COUNT(*) as total_users
FROM experimentation.fact_activation
WHERE signup_date >= CURRENT_DATE - INTERVAL '30' DAY;
```

### 5. Set Up Airflow (Optional)

Copy the DAG file to your Airflow dags folder:

```bash
cp airflow/dags/experiment_reporting_dag.py $AIRFLOW_HOME/dags/
```

Update the DAG with your specific paths and connection details.

## Configuration

### Metric Parameters

You can customize metric definitions in `dbt_project.yml`:

```yaml
vars:
  # Sessionization idle timeout in minutes
  session_idle_timeout_minutes: 30
  
  # Activation criteria
  activation_actions_count: 3
  activation_days_window: 7
  
  # Retention cohort windows
  retention_day_windows: [1, 7, 14, 30]
```

## Troubleshooting

### Connection Issues

If you can't connect to Trino/Presto:
- Verify host and port in `profiles.yml`
- Check authentication method
- Ensure network access to database

### Missing Data

If metrics are empty:
- Verify source tables have data
- Check date filters in staging models
- Run `dbt test` to identify data quality issues

### Slow Queries

If queries are slow:
- Add partitioning to fact tables (by date)
- Increase parallelism in `profiles.yml` (threads)
- Consider materializing views as tables

## Next Steps

1. Customize metric definitions for your product
2. Run your first experiment analysis
3. Set up Slack alerts for anomalies
4. Create Tableau dashboards for readouts

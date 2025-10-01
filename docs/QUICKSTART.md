# Quick Start Guide

This guide will help you get started with the Experimentation Metric Layer in 15 minutes.

## Prerequisites

- Trino/Presto database access
- Python 3.7+
- Basic SQL knowledge

## Step 1: Install dbt (2 minutes)

```bash
pip install dbt-trino
```

## Step 2: Configure Database Connection (3 minutes)

Edit `profiles.yml`:

```yaml
experimentation_metric_layer:
  target: dev
  outputs:
    dev:
      type: trino
      host: your-trino-host.com
      port: 8080
      database: experimentation
      schema: public
      user: your_username
```

## Step 3: Prepare Your Data (5 minutes)

Create the required source tables in your database:

```sql
-- Experiments metadata
CREATE TABLE raw.experiments (
    experiment_id VARCHAR,
    experiment_name VARCHAR,
    start_date DATE,
    end_date DATE,
    primary_metric_id VARCHAR,
    hypothesis VARCHAR,
    control_ratio DOUBLE DEFAULT 0.5,
    treatment_ratio DOUBLE DEFAULT 0.5
);

-- User assignments
CREATE TABLE raw.experiment_assignments (
    experiment_id VARCHAR,
    user_id VARCHAR,
    variant_id VARCHAR,
    assignment_timestamp TIMESTAMP,
    user_cohort VARCHAR,
    assignment_method VARCHAR,
    assignment_hash VARCHAR
);

-- User events
CREATE TABLE raw.user_events (
    event_id VARCHAR,
    user_id VARCHAR,
    event_timestamp TIMESTAMP,
    event_type VARCHAR,
    session_id VARCHAR,
    converted BOOLEAN,
    revenue DOUBLE,
    error_occurred BOOLEAN,
    page_load_time_ms INTEGER
);
```

## Step 4: Run dbt (2 minutes)

```bash
# Build all models
dbt run

# Run tests
dbt test

# Generate documentation
dbt docs generate
dbt docs serve
```

## Step 5: Run Your First Analysis (3 minutes)

```sql
-- Check experiment quality
SELECT 
    experiment_id,
    has_srm,
    srm_severity
FROM sample_ratio_mismatch
WHERE experiment_id = 'your_experiment_id';

-- View results
SELECT 
    m.metric_name,
    r.control_mean,
    r.treatment_mean,
    r.relative_lift_pct,
    r.is_significant
FROM experiment_results r
JOIN metric_definitions m ON r.metric_id = m.metric_id
WHERE r.experiment_id = 'your_experiment_id';

-- Get recommendation
SELECT 
    experiment_name,
    recommendation,
    primary_lift_pct,
    failed_guardrails
FROM experiment_summary
WHERE experiment_id = 'your_experiment_id';
```

## Next Steps

1. **Customize Metrics**: Edit `models/metrics/metric_definitions.sql` to add your metrics
2. **Review Examples**: Check `analyses/example_experiment_analysis.sql`
3. **Read Architecture**: See `docs/ARCHITECTURE.md` for design details
4. **Explore Macros**: Use SQL functions in `macros/experiment_macros.sql`

## Common Issues

### Connection Error
- Verify Trino host and port
- Check network connectivity
- Confirm credentials

### No Data
- Ensure source tables exist
- Verify table names match `models/sources.yml`
- Check data is in expected format

### Test Failures
- Normal if source tables are empty
- Populate with sample data or modify tests

## Getting Help

- Check documentation: `dbt docs serve`
- Review examples in `analyses/`
- Read architecture docs in `docs/`

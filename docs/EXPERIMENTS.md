# Experiment Analysis Guide

## Overview

This guide explains how to use the SQL experiment templates for A/B testing and analysis.

---

## Experiment Workflow

1. **Define Experiment** - Log metadata in experiment registry
2. **Assign Users** - Populate experiment_assignments table
3. **Select Metric** - Choose canonical metric (DAU, activation, retention, etc.)
4. **Run Analysis** - Use SQL templates for statistical tests
5. **Check Guardrails** - Validate experiment quality
6. **Report Results** - Generate readouts with CI and p-values

---

## SQL Templates

### 1. Difference-in-Means Test

**Purpose:** Calculate mean difference between control and treatment with statistical significance.

**Methods:** 
- t-test
- Welch's test (unequal variances)

**Usage:**
```sql
{{ experiment_difference_in_means('experiment_id', 'metric_table') }}
```

**Example:**
```sql
-- Compare DAU between variants
{{ experiment_difference_in_means('exp_001', 'fact_dau') }}
```

**Output Columns:**
- `control_mean` - Mean metric value for control
- `treatment_mean` - Mean metric value for treatment
- `absolute_lift` - Absolute difference (treatment - control)
- `relative_lift_pct` - Relative lift as percentage
- `standard_error` - Standard error of the difference
- `ci_lower` / `ci_upper` - 95% confidence interval
- `t_statistic` - t-statistic for hypothesis test
- `p_value_range` - Significance level (< 0.01, < 0.05, etc.)
- `is_significant_p05` - Boolean flag for p < 0.05
- `is_significant_p01` - Boolean flag for p < 0.01

**Interpretation:**
- If `is_significant_p05 = TRUE` and `relative_lift_pct > 0`, treatment wins
- Check that `ci_lower` and `ci_upper` don't cross zero for confidence
- Larger sample sizes give narrower confidence intervals

---

### 2. CUPED (Variance Reduction)

**Purpose:** Reduce variance using pre-experiment covariates to increase statistical power.

**Usage:**
```sql
{{ experiment_cuped('experiment_id', 'metric_table', 'covariate_table') }}
```

**Example:**
```sql
-- Use pre-experiment DAU to reduce variance
{{ experiment_cuped('exp_001', 'fact_dau', 'fact_dau_pre_experiment') }}
```

**Output Columns:**
- All columns from difference-in-means test
- `variance_reduction_pct` - Percentage variance reduction from CUPED
- `method` - 'CUPED-adjusted'

**When to Use:**
- When you have reliable pre-experiment data for users
- For metrics with high baseline variance
- To increase sensitivity for detecting small effects

**Expected Variance Reduction:**
- Typical: 20-40%
- Strong correlation: 50-70%
- Weak correlation: 5-15%

---

### 3. Guardrails (Quality Checks)

**Purpose:** Validate experiment integrity before trusting results.

**Usage:**
```sql
{{ experiment_guardrails('experiment_id') }}
```

**Example:**
```sql
{{ experiment_guardrails('exp_001') }}
```

**Checks Performed:**

1. **Sample Ratio Mismatch (SRM)**
   - Verifies variant allocation is balanced
   - Fails if ratio deviates > 5%
   - Warns if ratio deviates > 2%

2. **Outlier Detection**
   - Flags users with extreme metric values (> 3 std devs)
   - Fails if outlier rate > 5%
   - Warns if outlier rate > 2%

3. **Null Rate Check**
   - Detects missing metric data for assigned users
   - Fails if null rate > 50%
   - Warns if null rate > 30%

**Output Columns:**
- `overall_status` - PASS / WARNING / FAIL
- `srm_status` - SRM check status
- `outlier_status` - Outlier check status
- `null_rate_status` - Null rate check status
- `recommendation` - Human-readable action

**Best Practice:**
Always run guardrails BEFORE trusting experiment results. If status is FAIL, investigate before making decisions.

---

## Complete Analysis Example

```sql
-- Step 1: Check experiment quality
WITH guardrails AS (
    {{ experiment_guardrails('exp_001') }}
),

-- Step 2: Run primary analysis (DAU)
dau_results AS (
    {{ experiment_difference_in_means('exp_001', 'fact_dau') }}
),

-- Step 3: Run activation analysis
activation_results AS (
    {{ experiment_difference_in_means('exp_001', 'fact_activation') }}
),

-- Step 4: Run retention analysis
retention_results AS (
    {{ experiment_difference_in_means('exp_001', 'fact_retention') }}
)

-- Combine results
SELECT 'DAU' as metric, * FROM dau_results
UNION ALL
SELECT 'Activation' as metric, * FROM activation_results
UNION ALL
SELECT 'Retention' as metric, * FROM retention_results;

-- Check guardrails
SELECT * FROM guardrails;
```

---

## Experiment Registry

### Creating an Experiment

Add entry to experiment registry:

```sql
INSERT INTO experiment_registry VALUES (
    'exp_001',                          -- experiment_id
    'Homepage CTA Color Test',          -- experiment_name
    'Green CTA will increase clicks',   -- hypothesis
    '2024-01-01',                       -- start_date
    '2024-01-14',                       -- end_date
    'running',                          -- status
    'pm-jane',                          -- owner
    'fact_dau',                         -- target_metric
    0.05,                               -- min_detectable_effect (5%)
    0.80,                               -- statistical_power (80%)
    10000,                              -- sample_size_per_variant
    NOW(),                              -- created_at
    NOW()                               -- updated_at
);
```

### Assigning Users

Populate experiment assignments:

```sql
INSERT INTO experiment_assignments
SELECT 
    'exp_001' as experiment_id,
    user_id,
    CASE WHEN random() < 0.5 THEN 'control' ELSE 'treatment' END as variant,
    NOW() as assigned_at,
    NOW() as exposure_timestamp,
    country,
    platform
FROM users
WHERE is_eligible = TRUE
LIMIT 20000;
```

---

## Statistical Considerations

### Sample Size

Calculate required sample size:

```
n = 2 * (Z_α/2 + Z_β)² * σ² / Δ²

Where:
- Z_α/2 = 1.96 for 95% confidence
- Z_β = 0.84 for 80% power
- σ = standard deviation of metric
- Δ = minimum detectable effect
```

For a metric with σ = 10 and MDE = 5%:
```
n = 2 * (1.96 + 0.84)² * 100 / 0.25 = 6,272 per variant
```

### Multiple Testing Correction

If testing multiple metrics, apply Bonferroni correction:

```
Adjusted α = 0.05 / number_of_metrics
```

For 5 metrics: α = 0.05 / 5 = 0.01

Use `is_significant_p01` instead of `is_significant_p05`.

### When to Stop an Experiment

Stop when:
1. **Reached target sample size** AND **reached target duration**
2. **Guardrails fail** (SRM, data quality issues)
3. **Severe negative impact** on guardrail metrics

Never stop early just because results look good (increases false positives).

---

## Automated Reporting

Use Airflow DAG for weekly experiment readouts:

```bash
# Deploy DAG
cp airflow/dags/experiment_reporting_dag.py $AIRFLOW_HOME/dags/

# Manually trigger
airflow dags trigger experiment_reporting_weekly
```

The DAG will:
1. Refresh metric tables
2. Run experiment analysis for all active experiments
3. Execute quality checks
4. Generate readouts
5. Send Slack notifications

---

## Best Practices

### DO ✅
- Always run guardrails before trusting results
- Use canonical metrics for consistency
- Document hypothesis before starting
- Wait for sufficient sample size
- Check confidence intervals, not just p-values
- Consider practical significance (not just statistical)

### DON'T ❌
- Stop experiments early because they look good
- Cherry-pick metrics after seeing results
- Run experiments without guardrail checks
- Trust results with SRM failures
- Ignore null rate or outlier warnings
- Make decisions on borderline p-values (p ~ 0.05)

---

## Troubleshooting

### High Variance

If confidence intervals are too wide:
- Increase sample size
- Run experiment longer
- Use CUPED for variance reduction
- Consider stratification by high-variance segments

### SRM Failures

If sample ratios are imbalanced:
- Check randomization logic
- Look for bot traffic
- Verify assignment timing
- Check for interference between units

### Null Metric Data

If many users have no metric data:
- Verify metric lookback window
- Check for data pipeline delays
- Consider exposure-based analysis
- Filter for exposed users only

---

## Additional Resources

- [Metrics Documentation](METRICS.md)
- [Setup Guide](SETUP.md)
- dbt docs: `dbt docs generate && dbt docs serve`

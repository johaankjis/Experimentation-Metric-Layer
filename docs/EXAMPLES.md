# Usage Examples

This document provides practical examples of using the Experimentation Metric Layer.

## Example 1: Basic Experiment Analysis

### Scenario
You've run an experiment testing a new checkout flow and want to analyze results.

### Step 1: Load Experiment Data
```sql
-- Insert experiment metadata
INSERT INTO raw.experiments VALUES (
    'checkout_redesign_v1',
    'Checkout Flow Redesign',
    DATE '2024-01-01',
    DATE '2024-01-14',
    'conversion_rate',
    'New one-page checkout will increase conversion by 5%',
    0.5,
    0.5
);
```

### Step 2: Check Quality Issues
```sql
-- Check for Sample Ratio Mismatch
SELECT 
    experiment_id,
    has_srm,
    srm_severity,
    actual_control_ratio,
    expected_control_ratio
FROM sample_ratio_mismatch
WHERE experiment_id = 'checkout_redesign_v1';

-- Expected output: has_srm = false
```

### Step 3: View Results
```sql
-- Get primary metric results
SELECT 
    control_mean,
    treatment_mean,
    relative_lift_pct,
    is_significant,
    ci_lower,
    ci_upper
FROM experiment_results
WHERE experiment_id = 'checkout_redesign_v1'
    AND metric_id = 'conversion_rate';

-- Example output:
-- control_mean: 0.150
-- treatment_mean: 0.165
-- relative_lift_pct: 10.0
-- is_significant: true
```

### Step 4: Get Recommendation
```sql
SELECT 
    recommendation,
    failed_guardrails
FROM experiment_summary
WHERE experiment_id = 'checkout_redesign_v1';

-- Expected: recommendation = 'ship'
```

---

## Example 2: Guardrail Metric Violation

### Scenario
An experiment improves conversions but degrades page load time.

### Check All Metrics
```sql
SELECT 
    m.metric_name,
    m.is_guardrail,
    r.control_mean,
    r.treatment_mean,
    r.relative_lift_pct,
    r.is_significant,
    r.result_direction
FROM experiment_results r
JOIN metric_definitions m ON r.metric_id = m.metric_id
WHERE r.experiment_id = 'your_experiment'
ORDER BY m.is_guardrail DESC;
```

### Example Output
```
metric_name          | is_guardrail | control_mean | treatment_mean | relative_lift | is_significant | result_direction
---------------------|--------------|--------------|----------------|---------------|----------------|------------------
Page Load Time       | true         | 250          | 500            | 100.0         | true           | significantly_negative
Error Rate           | true         | 0.01         | 0.01           | 0.0           | false          | negative_not_significant
Conversion Rate      | false        | 0.15         | 0.165          | 10.0          | true           | significantly_positive
```

**Decision**: Do not ship - guardrail violated (page load time doubled)

---

## Example 3: Detecting Anomalies

### Scenario
You notice unusual metric values during an experiment.

### Check for Anomalies
```sql
SELECT 
    metric_id,
    variant_id,
    metric_value,
    baseline_mean,
    z_score,
    anomaly_severity,
    anomaly_direction
FROM metric_anomalies
WHERE experiment_id = 'your_experiment'
    AND is_anomaly = true;
```

### Example Output
```
metric_id       | variant_id | metric_value | baseline_mean | z_score | anomaly_severity | anomaly_direction
----------------|------------|--------------|---------------|---------|------------------|------------------
conversion_rate | treatment  | 0.75         | 0.15          | 8.5     | critical         | abnormally_high
```

**Interpretation**: Treatment group shows suspiciously high conversion rate. Investigate:
- Data pipeline issues
- Instrumentation bugs
- Selection bias
- Bot traffic

---

## Example 4: Sample Size Calculation

### Scenario
You're planning an experiment and need to know how many users are required.

### Calculate Required Sample Size
```sql
-- For a conversion rate experiment
-- Baseline: 15%, Want to detect: 2pp lift, 95% confidence, 80% power
SELECT 
    {{ calculate_required_sample_size(0.15, 0.02, 0.05, 0.80) }} AS min_users_per_variant;

-- Output: ~16,000 users per variant needed
```

### Estimate Duration
```sql
-- If you have 10,000 daily active users and 50% traffic allocation
WITH sample_size AS (
    SELECT 16000 AS required_per_variant
),
traffic AS (
    SELECT 
        10000 AS daily_users,
        0.5 AS traffic_allocation
)
SELECT 
    CEIL(s.required_per_variant / (t.daily_users * t.traffic_allocation)) AS days_needed
FROM sample_size s, traffic t;

-- Output: 4 days minimum
```

---

## Example 5: Multiple Experiments

### Scenario
You're running multiple simultaneous experiments.

### Check All Active Experiments
```sql
SELECT 
    experiment_id,
    experiment_name,
    status,
    total_users,
    primary_lift_pct,
    primary_is_significant,
    failed_guardrails,
    recommendation
FROM experiment_summary
WHERE status = 'running'
ORDER BY primary_lift_pct DESC;
```

### Identify Conflicts
```sql
-- Check for user overlap between experiments
SELECT 
    e1.experiment_id AS exp1,
    e2.experiment_id AS exp2,
    COUNT(DISTINCT e1.user_id) AS overlapping_users
FROM experiment_assignments e1
JOIN experiment_assignments e2 
    ON e1.user_id = e2.user_id
    AND e1.experiment_id < e2.experiment_id
WHERE e1.experiment_id IN ('exp1', 'exp2')
    AND e2.experiment_id IN ('exp1', 'exp2')
GROUP BY 1, 2;
```

---

## Example 6: Segmented Analysis

### Scenario
You want to analyze experiment results by user segment.

### Create Segmented Analysis
```sql
WITH user_segments AS (
    SELECT 
        user_id,
        CASE 
            WHEN user_tenure_days < 30 THEN 'new_users'
            WHEN user_tenure_days < 365 THEN 'active_users'
            ELSE 'power_users'
        END AS segment
    FROM users
),
segmented_results AS (
    SELECT 
        ea.experiment_id,
        ea.variant_id,
        us.segment,
        AVG(mc.metric_value) AS avg_metric_value,
        COUNT(DISTINCT ea.user_id) AS user_count
    FROM experiment_assignments ea
    JOIN metric_calculations mc 
        ON ea.experiment_id = mc.experiment_id
        AND ea.user_id = mc.user_id
    JOIN user_segments us ON ea.user_id = us.user_id
    WHERE ea.experiment_id = 'your_experiment'
        AND mc.metric_id = 'conversion_rate'
    GROUP BY 1, 2, 3
)
SELECT 
    segment,
    MAX(CASE WHEN variant_id = 'control' THEN avg_metric_value END) AS control_value,
    MAX(CASE WHEN variant_id = 'treatment' THEN avg_metric_value END) AS treatment_value,
    {{ calculate_relative_lift(
        MAX(CASE WHEN variant_id = 'treatment' THEN avg_metric_value END),
        MAX(CASE WHEN variant_id = 'control' THEN avg_metric_value END)
    ) }} AS lift_pct
FROM segmented_results
GROUP BY 1;
```

---

## Example 7: Time Series Analysis

### Scenario
You want to see how metrics evolved over the experiment duration.

### Daily Metric Trends
```sql
SELECT 
    DATE(mc.calculated_at) AS date,
    ea.variant_id,
    AVG(mc.metric_value) AS daily_avg,
    COUNT(DISTINCT mc.user_id) AS daily_users
FROM metric_calculations mc
JOIN experiment_assignments ea 
    ON mc.experiment_id = ea.experiment_id
    AND mc.user_id = ea.user_id
WHERE mc.experiment_id = 'your_experiment'
    AND mc.metric_id = 'conversion_rate'
GROUP BY 1, 2
ORDER BY 1, 2;
```

### Visualize in BI Tool
The above query can be connected to Tableau, Looker, or any BI tool for visualization.

---

## Example 8: Power Analysis Post-Hoc

### Scenario
Experiment shows no significant result. Was sample size sufficient?

### Check Statistical Power
```sql
WITH experiment_stats AS (
    SELECT 
        experiment_id,
        control_size,
        treatment_size,
        ABS(treatment_mean - control_mean) AS observed_effect
    FROM experiment_results
    WHERE experiment_id = 'your_experiment'
        AND metric_id = 'conversion_rate'
)
SELECT 
    experiment_id,
    control_size,
    treatment_size,
    observed_effect,
    {{ calculate_statistical_power(
        control_size,
        observed_effect,
        0.05
    ) }} AS estimated_power
FROM experiment_stats;
```

**Interpretation**:
- Power < 0.5: Underpowered, need more data
- Power 0.5-0.8: Marginally powered
- Power > 0.8: Well powered

---

## Example 9: Metric Correlation Check

### Scenario
You want to understand if metrics move together.

### Calculate Metric Correlations
```sql
SELECT 
    m1.metric_id AS metric1,
    m2.metric_id AS metric2,
    CORR(m1.metric_value, m2.metric_value) AS correlation
FROM metric_calculations m1
JOIN metric_calculations m2 
    ON m1.experiment_id = m2.experiment_id
    AND m1.user_id = m2.user_id
    AND m1.variant_id = m2.variant_id
    AND m1.metric_id < m2.metric_id
WHERE m1.experiment_id = 'your_experiment'
GROUP BY 1, 2
ORDER BY ABS(correlation) DESC;
```

---

## Example 10: Export for Further Analysis

### Scenario
You want to export data for advanced statistical analysis in R or Python.

### Export Complete Dataset
```sql
-- Export experiment data
SELECT 
    ea.experiment_id,
    ea.user_id,
    ea.variant_id,
    mc.metric_id,
    mc.metric_value,
    mc.sample_size
FROM experiment_assignments ea
LEFT JOIN metric_calculations mc 
    ON ea.experiment_id = mc.experiment_id
    AND ea.user_id = mc.user_id
WHERE ea.experiment_id = 'your_experiment'
ORDER BY ea.user_id, mc.metric_id;
```

Save as CSV and analyze with your preferred statistical package.

---

## Best Practices Summary

1. **Always check SRM first** - Invalid randomization invalidates all results
2. **Monitor guardrails** - Never ship with failed guardrails
3. **Check for anomalies** - Unusual values indicate data issues
4. **Calculate sample size upfront** - Avoid underpowered experiments
5. **Document hypothesis** - Write down what you expect before analyzing
6. **Use confidence intervals** - Point estimates alone are misleading
7. **Consider segments** - Effects may vary by user type
8. **Monitor over time** - Look for novelty effects or time trends
9. **Multiple testing correction** - Be careful with many metrics
10. **Iterate and learn** - Use insights to design better experiments

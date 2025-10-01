/*
    Example: Complete Experiment Analysis
    
    This analysis demonstrates how to use the experimentation metric layer
    to analyze an A/B test from start to finish.
    
    Steps:
    1. Check experiment configuration and sample sizes
    2. Run quality checks (SRM, anomalies)
    3. Analyze primary metric
    4. Check guardrail metrics
    5. Make a ship/no-ship decision
*/

-- 1. Experiment Overview
SELECT
    experiment_id,
    experiment_name,
    status,
    total_users,
    control_users,
    treatment_users,
    CAST(treatment_users AS DOUBLE) / total_users AS treatment_ratio
FROM {{ ref('experiment_summary') }}
WHERE experiment_id = 'exp_123';

-- 2. Quality Checks: Sample Ratio Mismatch
SELECT
    experiment_id,
    has_srm,
    srm_severity,
    expected_control_ratio,
    actual_control_ratio,
    control_ratio_diff,
    chi_square_statistic
FROM {{ ref('sample_ratio_mismatch') }}
WHERE experiment_id = 'exp_123';

-- 3. Quality Checks: Metric Anomalies
SELECT
    metric_id,
    variant_id,
    is_anomaly,
    anomaly_severity,
    anomaly_direction,
    metric_value,
    baseline_mean,
    z_score
FROM {{ ref('metric_anomalies') }}
WHERE experiment_id = 'exp_123'
    AND is_anomaly = true
ORDER BY ABS(z_score) DESC;

-- 4. Primary Metric Analysis
SELECT
    r.metric_id,
    m.metric_name,
    r.control_mean,
    r.treatment_mean,
    r.absolute_lift,
    r.relative_lift_pct,
    r.is_significant,
    r.result_direction,
    r.ci_lower,
    r.ci_upper
FROM {{ ref('experiment_results') }} r
INNER JOIN {{ ref('metric_definitions') }} m ON r.metric_id = m.metric_id
WHERE r.experiment_id = 'exp_123'
    AND r.metric_id = (
        SELECT primary_metric_id 
        FROM {{ source('raw', 'experiments') }}
        WHERE experiment_id = 'exp_123'
    );

-- 5. All Metrics (Including Guardrails)
SELECT
    r.metric_id,
    m.metric_name,
    m.is_guardrail,
    r.control_mean,
    r.treatment_mean,
    r.relative_lift_pct,
    r.is_significant,
    r.result_direction,
    CASE
        WHEN m.is_guardrail AND r.result_direction = 'significantly_negative' 
        THEN 'FAILED'
        ELSE 'PASSED'
    END AS guardrail_status
FROM {{ ref('experiment_results') }} r
INNER JOIN {{ ref('metric_definitions') }} m ON r.metric_id = m.metric_id
WHERE r.experiment_id = 'exp_123'
ORDER BY m.is_guardrail DESC, r.is_significant DESC;

-- 6. Ship Decision Summary
SELECT
    experiment_id,
    experiment_name,
    recommendation,
    primary_is_significant,
    primary_lift_pct,
    failed_guardrails,
    failed_guardrail_metrics,
    CASE
        WHEN recommendation = 'ship' THEN 
            'Ship this experiment - primary metric shows significant positive lift with no guardrail violations'
        WHEN recommendation = 'do_not_ship' THEN 
            'Do not ship - either negative primary metric or guardrail violations'
        ELSE 
            'Needs more data - results not yet significant'
    END AS decision_rationale
FROM {{ ref('experiment_summary') }}
WHERE experiment_id = 'exp_123';

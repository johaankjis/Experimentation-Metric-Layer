{{ config(
    materialized='view',
    tags=['anomaly_detection', 'quality']
) }}

/*
    Metric Anomaly Detection
    
    Identifies unusual metric values in experiments by comparing against
    historical baselines.
    
    Flags anomalies when metric values are more than 3 standard deviations
    from the historical mean (99.7% confidence interval).
    
    This helps identify:
    - Data quality issues
    - Instrumentation problems
    - Unexpected experiment effects
*/

WITH historical_baselines AS (
    SELECT
        metric_id,
        AVG(metric_value) AS baseline_mean,
        STDDEV(metric_value) AS baseline_stddev,
        MIN(metric_value) AS baseline_min,
        MAX(metric_value) AS baseline_max,
        COUNT(*) AS baseline_sample_size
    FROM {{ ref('metric_calculations') }}
    WHERE 
        -- Use data from non-experiment periods or completed experiments
        experiment_id NOT IN (
            SELECT experiment_id 
            FROM {{ source('raw', 'experiments') }}
            WHERE end_date IS NULL OR end_date >= CURRENT_DATE
        )
    GROUP BY 1
    HAVING COUNT(*) >= 30  -- Minimum sample size for baseline
),

current_metrics AS (
    SELECT
        mc.experiment_id,
        mc.metric_id,
        mc.variant_id,
        AVG(mc.metric_value) AS metric_value,
        COUNT(*) AS sample_size
    FROM {{ ref('metric_calculations') }} mc
    WHERE 
        -- Only active experiments
        experiment_id IN (
            SELECT experiment_id 
            FROM {{ source('raw', 'experiments') }}
            WHERE end_date IS NULL OR end_date >= CURRENT_DATE
        )
    GROUP BY 1, 2, 3
),

anomaly_detection AS (
    SELECT
        c.experiment_id,
        c.metric_id,
        c.variant_id,
        c.metric_value,
        c.sample_size,
        b.baseline_mean,
        b.baseline_stddev,
        b.baseline_min,
        b.baseline_max,
        
        -- Calculate z-score
        CASE 
            WHEN b.baseline_stddev = 0 OR b.baseline_stddev IS NULL THEN NULL
            ELSE (c.metric_value - b.baseline_mean) / b.baseline_stddev
        END AS z_score,
        
        -- Percent difference from baseline
        CASE
            WHEN b.baseline_mean = 0 THEN NULL
            ELSE ((c.metric_value - b.baseline_mean) / b.baseline_mean) * 100
        END AS pct_diff_from_baseline
        
    FROM current_metrics c
    INNER JOIN historical_baselines b ON c.metric_id = b.metric_id
)

SELECT
    experiment_id,
    metric_id,
    variant_id,
    metric_value,
    sample_size,
    baseline_mean,
    baseline_stddev,
    baseline_min,
    baseline_max,
    z_score,
    pct_diff_from_baseline,
    
    -- Flag anomalies (3 sigma threshold)
    CASE 
        WHEN ABS(z_score) > 3 THEN true 
        ELSE false 
    END AS is_anomaly,
    
    -- Severity classification
    CASE
        WHEN ABS(z_score) > 5 THEN 'critical'
        WHEN ABS(z_score) > 3 THEN 'high'
        WHEN ABS(z_score) > 2 THEN 'medium'
        ELSE 'normal'
    END AS anomaly_severity,
    
    -- Direction
    CASE
        WHEN z_score > 3 THEN 'abnormally_high'
        WHEN z_score < -3 THEN 'abnormally_low'
        WHEN z_score > 0 THEN 'higher_than_baseline'
        WHEN z_score < 0 THEN 'lower_than_baseline'
        ELSE 'within_normal_range'
    END AS anomaly_direction,
    
    CURRENT_TIMESTAMP AS checked_at

FROM anomaly_detection
WHERE z_score IS NOT NULL

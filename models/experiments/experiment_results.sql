{{ config(
    materialized='table',
    tags=['experiments', 'analysis']
) }}

/*
    Statistical analysis of experiment results
    
    This model calculates key statistics for each metric in each experiment:
    - Mean values for control and treatment
    - Absolute and relative lift
    - Statistical significance (simplified z-test approach)
    
    Note: This uses simplified statistical formulas suitable for large samples.
    For production use, consider more sophisticated methods (t-test, sequential testing, etc.)
*/

WITH experiment_metrics AS (
    -- This would join with actual experiment data
    -- For now, we'll create a template structure
    SELECT
        experiment_id,
        variant_id,
        metric_id,
        AVG(metric_value) AS mean_value,
        STDDEV(metric_value) AS stddev_value,
        COUNT(*) AS sample_size
    FROM {{ ref('metric_calculations') }}
    GROUP BY 1, 2, 3
),

control_metrics AS (
    SELECT
        experiment_id,
        metric_id,
        mean_value AS control_mean,
        stddev_value AS control_stddev,
        sample_size AS control_size
    FROM experiment_metrics
    WHERE variant_id = 'control'
),

treatment_metrics AS (
    SELECT
        experiment_id,
        metric_id,
        mean_value AS treatment_mean,
        stddev_value AS treatment_stddev,
        sample_size AS treatment_size
    FROM experiment_metrics
    WHERE variant_id = 'treatment'
),

statistical_tests AS (
    SELECT
        c.experiment_id,
        c.metric_id,
        c.control_mean,
        t.treatment_mean,
        c.control_stddev,
        t.treatment_stddev,
        c.control_size,
        t.treatment_size,
        
        -- Calculate absolute lift
        t.treatment_mean - c.control_mean AS absolute_lift,
        
        -- Calculate relative lift (percentage change)
        CASE 
            WHEN c.control_mean = 0 THEN NULL
            ELSE ((t.treatment_mean - c.control_mean) / c.control_mean) * 100
        END AS relative_lift_pct,
        
        -- Calculate standard error for difference
        SQRT(
            (POWER(c.control_stddev, 2) / c.control_size) +
            (POWER(t.treatment_stddev, 2) / t.treatment_size)
        ) AS standard_error,
        
        -- Calculate z-score
        CASE 
            WHEN SQRT(
                (POWER(c.control_stddev, 2) / c.control_size) +
                (POWER(t.treatment_stddev, 2) / t.treatment_size)
            ) = 0 THEN NULL
            ELSE (t.treatment_mean - c.control_mean) / SQRT(
                (POWER(c.control_stddev, 2) / c.control_size) +
                (POWER(t.treatment_stddev, 2) / t.treatment_size)
            )
        END AS z_score
        
    FROM control_metrics c
    INNER JOIN treatment_metrics t
        ON c.experiment_id = t.experiment_id
        AND c.metric_id = t.metric_id
)

SELECT
    experiment_id,
    metric_id,
    control_mean,
    treatment_mean,
    control_stddev,
    treatment_stddev,
    control_size,
    treatment_size,
    absolute_lift,
    relative_lift_pct,
    standard_error,
    z_score,
    
    -- Calculate confidence intervals (95%)
    treatment_mean - (1.96 * standard_error) AS ci_lower,
    treatment_mean + (1.96 * standard_error) AS ci_upper,
    
    -- Approximate p-value (two-tailed test)
    -- Simplified: using threshold approach
    CASE 
        WHEN ABS(z_score) >= 1.96 THEN 0.05  -- Significant at 95% confidence
        WHEN ABS(z_score) >= 1.645 THEN 0.10  -- Significant at 90% confidence
        ELSE 1.0  -- Not significant
    END AS p_value_approx,
    
    -- Flag statistical significance
    CASE WHEN ABS(z_score) >= 1.96 THEN true ELSE false END AS is_significant,
    
    -- Directional indicator
    CASE 
        WHEN z_score > 1.96 THEN 'significantly_positive'
        WHEN z_score < -1.96 THEN 'significantly_negative'
        WHEN z_score > 0 THEN 'positive_not_significant'
        ELSE 'negative_not_significant'
    END AS result_direction,
    
    CURRENT_TIMESTAMP AS calculated_at

FROM statistical_tests

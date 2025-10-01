{{ config(
    materialized='view',
    tags=['anomaly_detection', 'quality']
) }}

/*
    Sample Ratio Mismatch (SRM) Detection
    
    Detects when the actual ratio of users in experiment variants
    differs significantly from the expected ratio.
    
    SRM is a critical experiment quality issue that can indicate:
    - Randomization problems
    - Data pipeline issues
    - Selection bias
    
    Uses chi-square test with p-value threshold of 0.001
*/

WITH experiment_config AS (
    SELECT
        experiment_id,
        COALESCE(control_ratio, 0.5) AS expected_control_ratio,
        COALESCE(treatment_ratio, 0.5) AS expected_treatment_ratio
    FROM {{ source('raw', 'experiments') }}
),

actual_assignments AS (
    SELECT
        experiment_id,
        COUNT(DISTINCT CASE WHEN variant_id = 'control' THEN user_id END) AS control_count,
        COUNT(DISTINCT CASE WHEN variant_id = 'treatment' THEN user_id END) AS treatment_count,
        COUNT(DISTINCT user_id) AS total_count
    FROM {{ ref('experiment_assignments') }}
    GROUP BY 1
),

srm_calculation AS (
    SELECT
        a.experiment_id,
        c.expected_control_ratio,
        c.expected_treatment_ratio,
        a.control_count,
        a.treatment_count,
        a.total_count,
        
        -- Actual ratios
        CAST(a.control_count AS DOUBLE) / a.total_count AS actual_control_ratio,
        CAST(a.treatment_count AS DOUBLE) / a.total_count AS actual_treatment_ratio,
        
        -- Expected counts based on configuration
        c.expected_control_ratio * a.total_count AS expected_control_count,
        c.expected_treatment_ratio * a.total_count AS expected_treatment_count,
        
        -- Chi-square statistic: sum((observed - expected)^2 / expected)
        POWER(a.control_count - (c.expected_control_ratio * a.total_count), 2) / 
            (c.expected_control_ratio * a.total_count) +
        POWER(a.treatment_count - (c.expected_treatment_ratio * a.total_count), 2) / 
            (c.expected_treatment_ratio * a.total_count) AS chi_square_statistic
            
    FROM actual_assignments a
    INNER JOIN experiment_config c ON a.experiment_id = c.experiment_id
)

SELECT
    experiment_id,
    expected_control_ratio,
    actual_control_ratio,
    expected_treatment_ratio,
    actual_treatment_ratio,
    control_count,
    treatment_count,
    total_count,
    chi_square_statistic,
    
    -- Chi-square critical value for df=1 at p=0.001 is 10.828
    CASE 
        WHEN chi_square_statistic > 10.828 THEN true 
        ELSE false 
    END AS has_srm,
    
    -- Severity classification
    CASE
        WHEN chi_square_statistic > 10.828 THEN 'critical'
        WHEN chi_square_statistic > 6.635 THEN 'warning'  -- p=0.01
        ELSE 'ok'
    END AS srm_severity,
    
    -- Ratio difference
    ABS(actual_control_ratio - expected_control_ratio) AS control_ratio_diff,
    
    CURRENT_TIMESTAMP AS checked_at

FROM srm_calculation

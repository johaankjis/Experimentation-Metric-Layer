{{ config(
    materialized='table',
    tags=['metrics', 'calculations']
) }}

/*
    Metric Calculations
    
    This model calculates metric values for each user in each experiment variant.
    
    It joins:
    - Experiment assignments (which users are in which variants)
    - User events (actual user behavior)
    - Metric definitions (how to calculate each metric)
    
    The output is a row per user per metric per experiment, with calculated values.
*/

WITH user_experiment_metrics AS (
    SELECT
        a.experiment_id,
        a.user_id,
        a.variant_id,
        e.experiment_name,
        m.metric_id,
        m.metric_name,
        
        -- Calculate metric values based on metric type
        -- This is a simplified example; real implementation would be more complex
        CASE m.metric_type
            WHEN 'ratio' THEN 
                -- For ratio metrics, calculate numerator/denominator per user
                NULL  -- Placeholder - would use metric-specific logic
            WHEN 'count' THEN
                -- For count metrics, sum events per user
                NULL  -- Placeholder
            WHEN 'average' THEN
                -- For average metrics, mean per user
                NULL  -- Placeholder
            ELSE NULL
        END AS metric_value,
        
        -- Metadata
        COUNT(*) AS observation_count,
        MIN(event_timestamp) AS first_observation,
        MAX(event_timestamp) AS last_observation
        
    FROM {{ ref('experiment_assignments') }} a
    INNER JOIN {{ source('raw', 'experiments') }} e 
        ON a.experiment_id = e.experiment_id
    INNER JOIN {{ ref('metric_definitions') }} m
        ON 1=1  -- All metrics for all experiments
    LEFT JOIN {{ source('raw', 'user_events') }} ue
        ON a.user_id = ue.user_id
        AND {{ get_experiment_date_filter('e.start_date', 'e.end_date') }}
    
    GROUP BY 1, 2, 3, 4, 5, 6, m.metric_type
)

SELECT
    experiment_id,
    user_id,
    variant_id,
    metric_id,
    metric_value,
    observation_count AS sample_size,
    first_observation,
    last_observation,
    CURRENT_TIMESTAMP AS calculated_at
FROM user_experiment_metrics
WHERE metric_value IS NOT NULL

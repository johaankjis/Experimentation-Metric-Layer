{{ config(
    materialized='table',
    tags=['experiments', 'summary']
) }}

/*
    High-level experiment summary
    
    Provides an overview of each experiment including:
    - Basic metadata (name, dates, status)
    - Sample size information
    - Primary metric results
    - Guardrail metric status
*/

WITH experiment_metadata AS (
    SELECT
        experiment_id,
        experiment_name,
        start_date,
        end_date,
        CASE 
            WHEN end_date IS NULL THEN 'running'
            WHEN end_date >= CURRENT_DATE THEN 'running'
            ELSE 'completed'
        END AS status,
        primary_metric_id,
        hypothesis
    FROM {{ source('raw', 'experiments') }}
),

user_counts AS (
    SELECT
        experiment_id,
        COUNT(DISTINCT user_id) AS total_users,
        COUNT(DISTINCT CASE WHEN variant_id = 'control' THEN user_id END) AS control_users,
        COUNT(DISTINCT CASE WHEN variant_id = 'treatment' THEN user_id END) AS treatment_users
    FROM {{ ref('experiment_assignments') }}
    GROUP BY 1
),

primary_results AS (
    SELECT
        r.experiment_id,
        r.control_mean AS primary_control_mean,
        r.treatment_mean AS primary_treatment_mean,
        r.relative_lift_pct AS primary_lift_pct,
        r.is_significant AS primary_is_significant,
        r.result_direction AS primary_direction
    FROM {{ ref('experiment_results') }} r
    INNER JOIN experiment_metadata m
        ON r.experiment_id = m.experiment_id
        AND r.metric_id = m.primary_metric_id
),

guardrail_status AS (
    SELECT
        r.experiment_id,
        COUNT(*) AS total_guardrails,
        COUNT(CASE WHEN r.result_direction = 'significantly_negative' THEN 1 END) AS failed_guardrails,
        ARRAY_AGG(
            CASE 
                WHEN r.result_direction = 'significantly_negative' 
                THEN r.metric_id 
            END
        ) AS failed_guardrail_metrics
    FROM {{ ref('experiment_results') }} r
    INNER JOIN {{ ref('metric_definitions') }} m
        ON r.metric_id = m.metric_id
        AND m.is_guardrail = true
    GROUP BY 1
)

SELECT
    m.experiment_id,
    m.experiment_name,
    m.start_date,
    m.end_date,
    m.status,
    m.hypothesis,
    
    -- Sample sizes
    u.total_users,
    u.control_users,
    u.treatment_users,
    
    -- Primary metric results
    m.primary_metric_id,
    p.primary_control_mean,
    p.primary_treatment_mean,
    p.primary_lift_pct,
    p.primary_is_significant,
    p.primary_direction,
    
    -- Guardrail metrics
    g.total_guardrails,
    g.failed_guardrails,
    g.failed_guardrail_metrics,
    
    -- Overall recommendation
    CASE
        WHEN g.failed_guardrails > 0 THEN 'do_not_ship'
        WHEN p.primary_is_significant AND p.primary_direction = 'significantly_positive' THEN 'ship'
        WHEN p.primary_is_significant AND p.primary_direction = 'significantly_negative' THEN 'do_not_ship'
        ELSE 'needs_more_data'
    END AS recommendation,
    
    CURRENT_TIMESTAMP AS updated_at

FROM experiment_metadata m
LEFT JOIN user_counts u ON m.experiment_id = u.experiment_id
LEFT JOIN primary_results p ON m.experiment_id = p.experiment_id
LEFT JOIN guardrail_status g ON m.experiment_id = g.experiment_id

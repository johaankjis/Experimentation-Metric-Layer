{{ config(
    materialized='table',
    tags=['metrics', 'reference']
) }}

/*
    Canonical metric definitions for experimentation
    
    This model defines all standard metrics used across experiments.
    Each metric has a unique ID and standardized calculation logic.
*/

WITH metric_catalog AS (
    SELECT
        'conversion_rate' AS metric_id,
        'Conversion Rate' AS metric_name,
        'ratio' AS metric_type,
        'COUNT(DISTINCT CASE WHEN converted = true THEN user_id END)' AS numerator_sql,
        'COUNT(DISTINCT user_id)' AS denominator_sql,
        false AS is_guardrail,
        'Primary success metric - percentage of users who converted' AS description
    
    UNION ALL
    
    SELECT
        'revenue_per_user' AS metric_id,
        'Revenue Per User' AS metric_name,
        'ratio' AS metric_type,
        'SUM(revenue)' AS numerator_sql,
        'COUNT(DISTINCT user_id)' AS denominator_sql,
        false AS is_guardrail,
        'Average revenue generated per user' AS description
    
    UNION ALL
    
    SELECT
        'sessions_per_user' AS metric_id,
        'Sessions Per User' AS metric_name,
        'ratio' AS metric_type,
        'COUNT(session_id)' AS numerator_sql,
        'COUNT(DISTINCT user_id)' AS denominator_sql,
        false AS is_guardrail,
        'Average number of sessions per user' AS description
    
    UNION ALL
    
    SELECT
        'error_rate' AS metric_id,
        'Error Rate' AS metric_name,
        'ratio' AS metric_type,
        'COUNT(DISTINCT CASE WHEN error_occurred = true THEN event_id END)' AS numerator_sql,
        'COUNT(DISTINCT event_id)' AS denominator_sql,
        true AS is_guardrail,
        'Percentage of events that resulted in errors - guardrail metric' AS description
    
    UNION ALL
    
    SELECT
        'page_load_time' AS metric_id,
        'Average Page Load Time' AS metric_name,
        'average' AS metric_type,
        'AVG(page_load_time_ms)' AS numerator_sql,
        NULL AS denominator_sql,
        true AS is_guardrail,
        'Average page load time in milliseconds - guardrail metric' AS description
    
    UNION ALL
    
    SELECT
        'active_users' AS metric_id,
        'Active Users' AS metric_name,
        'count' AS metric_type,
        'COUNT(DISTINCT user_id)' AS numerator_sql,
        NULL AS denominator_sql,
        false AS is_guardrail,
        'Total number of active users' AS description
    
    UNION ALL
    
    SELECT
        'retention_rate' AS metric_id,
        'Day 7 Retention Rate' AS metric_name,
        'ratio' AS metric_type,
        'COUNT(DISTINCT CASE WHEN days_since_first_visit >= 7 AND is_retained THEN user_id END)' AS numerator_sql,
        'COUNT(DISTINCT user_id)' AS denominator_sql,
        false AS is_guardrail,
        'Percentage of users who returned after 7 days' AS description
)

SELECT
    metric_id,
    metric_name,
    metric_type,
    numerator_sql,
    denominator_sql,
    is_guardrail,
    description,
    CURRENT_TIMESTAMP AS created_at
FROM metric_catalog

{{ config(
    materialized='table',
    tags=['experiments', 'assignments']
) }}

/*
    Experiment User Assignments
    
    This model tracks which users are assigned to which experiment variants.
    
    Key features:
    - First assignment timestamp is preserved
    - Users are assigned consistently throughout the experiment
    - Supports multiple simultaneous experiments
    
    Note: This is a template model. In production, this would typically
    be populated from an experiment assignment service or feature flag system.
*/

SELECT
    experiment_id,
    user_id,
    variant_id,
    assignment_timestamp,
    -- Additional assignment context
    user_cohort,
    assignment_method,
    assignment_hash
FROM {{ source('raw', 'experiment_assignments') }}

-- Ensure one assignment per user per experiment
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY experiment_id, user_id 
    ORDER BY assignment_timestamp
) = 1

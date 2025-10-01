{{
  config(
    materialized='table',
    tags=['experiments']
  )
}}

-- Experiment Registry
-- Central metadata table for all experiments
-- This is a template - populate from your experiment management system
select
    experiment_id,
    experiment_name,
    hypothesis,
    start_date,
    end_date,
    status,  -- draft, running, completed, stopped
    owner,   -- PM or DS owner
    target_metric,
    min_detectable_effect,
    statistical_power,
    sample_size_per_variant,
    created_at,
    updated_at
from {{ source('raw', 'experiments') }}
where experiment_id is not null

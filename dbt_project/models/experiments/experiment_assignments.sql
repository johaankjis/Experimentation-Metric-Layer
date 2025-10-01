{{
  config(
    materialized='table',
    tags=['experiments']
  )
}}

-- Experiment Assignment Table
-- Maps users to experiment variants
-- This is a template - populate from your experiment platform
select
    experiment_id,
    user_id,
    variant,
    assigned_at,
    exposure_timestamp,
    country,
    platform
from {{ source('raw', 'experiment_assignments') }}
where experiment_id is not null
  and user_id is not null
  and variant is not null

{{
  config(
    materialized='table',
    tags=['metrics', 'weekly_active_users']
  )
}}

-- Weekly Active Users (WAU) - Canonical Definition
-- A user is active in a week if they have at least one event
with weekly_activity as (
    select
        user_id,
        date_trunc('week', event_timestamp) as week_start,
        count(distinct event_id) as event_count,
        count(distinct date(event_timestamp)) as active_days,
        count(distinct session_id) as session_count
    from {{ ref('stg_events') }}
    group by 1, 2
)

select
    week_start,
    user_id,
    event_count,
    active_days,
    session_count,
    1 as is_active,
    event_count as metric_value
from weekly_activity

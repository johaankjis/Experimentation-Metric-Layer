{{
  config(
    materialized='table',
    tags=['metrics', 'daily_active_users']
  )
}}

-- Daily Active Users (DAU) - Canonical Definition
-- A user is active on a day if they have at least one event
with daily_activity as (
    select
        user_id,
        date(event_timestamp) as activity_date,
        count(distinct event_id) as event_count,
        count(distinct session_id) as session_count
    from {{ ref('stg_events') }}
    group by 1, 2
)

select
    activity_date,
    user_id,
    event_count,
    session_count,
    1 as is_active,
    event_count as metric_value
from daily_activity

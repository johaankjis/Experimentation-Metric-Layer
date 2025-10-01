{{
  config(
    materialized='table',
    tags=['metrics', 'monthly_active_users']
  )
}}

-- Monthly Active Users (MAU) - Canonical Definition
-- A user is active in a month if they have at least one event
with monthly_activity as (
    select
        user_id,
        date_trunc('month', event_timestamp) as month_start,
        count(distinct event_id) as event_count,
        count(distinct date(event_timestamp)) as active_days,
        count(distinct session_id) as session_count
    from {{ ref('stg_events') }}
    group by 1, 2
)

select
    month_start,
    user_id,
    event_count,
    active_days,
    session_count,
    1 as is_active,
    event_count as metric_value
from monthly_activity

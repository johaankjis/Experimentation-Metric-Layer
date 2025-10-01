{{
  config(
    materialized='table',
    tags=['metrics', 'sessionization']
  )
}}

-- Sessionization - Canonical Definition
-- Sessions are defined by idle timeout (default: 30 minutes between events)
with ordered_events as (
    select
        user_id,
        event_id,
        event_timestamp,
        event_name,
        lag(event_timestamp) over (partition by user_id order by event_timestamp) as prev_event_timestamp
    from {{ ref('stg_events') }}
),

session_markers as (
    select
        user_id,
        event_id,
        event_timestamp,
        event_name,
        prev_event_timestamp,
        -- Mark new session if gap > idle timeout
        case
            when prev_event_timestamp is null then 1
            when date_diff('minute', prev_event_timestamp, event_timestamp) > {{ var('session_idle_timeout_minutes', 30) }} then 1
            else 0
        end as is_new_session
    from ordered_events
),

session_ids as (
    select
        user_id,
        event_id,
        event_timestamp,
        event_name,
        -- Generate session_id by cumulative sum of session markers
        sum(is_new_session) over (partition by user_id order by event_timestamp) as session_number
    from session_markers
),

session_summary as (
    select
        user_id,
        session_number,
        min(event_timestamp) as session_start,
        max(event_timestamp) as session_end,
        count(distinct event_id) as event_count,
        date_diff('minute', min(event_timestamp), max(event_timestamp)) as session_duration_minutes
    from session_ids
    group by 1, 2
)

select
    user_id,
    session_number,
    session_start,
    session_end,
    event_count,
    session_duration_minutes,
    session_duration_minutes as metric_value
from session_summary

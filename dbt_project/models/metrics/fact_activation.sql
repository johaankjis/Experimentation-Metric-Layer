{{
  config(
    materialized='table',
    tags=['metrics', 'activation']
  )
}}

-- Activation Metric - Canonical Definition
-- User is activated if they complete N actions within X days of signup
with user_signups as (
    select
        user_id,
        signup_date
    from {{ source('raw', 'users') }}
),

early_events as (
    select
        e.user_id,
        u.signup_date,
        e.event_timestamp,
        e.event_name,
        e.event_id,
        date_diff('day', u.signup_date, date(e.event_timestamp)) as days_since_signup
    from {{ ref('stg_events') }} e
    inner join user_signups u
        on e.user_id = u.user_id
    where date_diff('day', u.signup_date, date(e.event_timestamp)) between 0 and {{ var('activation_days_window', 7) }}
),

activation_status as (
    select
        user_id,
        signup_date,
        count(distinct event_id) as action_count,
        min(event_timestamp) as first_action_timestamp,
        case 
            when count(distinct event_id) >= {{ var('activation_actions_count', 3) }} then 1
            else 0
        end as is_activated
    from early_events
    group by 1, 2
)

select
    user_id,
    signup_date,
    action_count,
    first_action_timestamp,
    is_activated,
    is_activated as metric_value
from activation_status

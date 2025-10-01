{{
  config(
    materialized='table',
    tags=['metrics', 'retention']
  )
}}

-- Retention Cohorts - Canonical Definition
-- Tracks user retention at various day windows after signup
with user_signups as (
    select
        user_id,
        signup_date
    from {{ source('raw', 'users') }}
),

user_activity as (
    select
        user_id,
        date(event_timestamp) as activity_date
    from {{ ref('stg_events') }}
    group by 1, 2
),

retention_cohorts as (
    select
        s.user_id,
        s.signup_date,
        a.activity_date,
        date_diff('day', s.signup_date, a.activity_date) as days_since_signup
    from user_signups s
    left join user_activity a
        on s.user_id = a.user_id
        and a.activity_date >= s.signup_date
),

retention_metrics as (
    select
        user_id,
        signup_date,
        -- Day 1 retention
        max(case when days_since_signup = 1 then 1 else 0 end) as retained_day_1,
        -- Day 7 retention
        max(case when days_since_signup between 7 and 7 then 1 else 0 end) as retained_day_7,
        -- Day 14 retention
        max(case when days_since_signup between 14 and 14 then 1 else 0 end) as retained_day_14,
        -- Day 30 retention
        max(case when days_since_signup between 30 and 30 then 1 else 0 end) as retained_day_30
    from retention_cohorts
    group by 1, 2
)

select
    user_id,
    signup_date,
    retained_day_1,
    retained_day_7,
    retained_day_14,
    retained_day_30,
    retained_day_7 as metric_value  -- Default metric value is day 7 retention
from retention_metrics

{{
  config(
    materialized='view'
  )
}}

-- Staging model for raw event data
-- This is a template - adapt to your actual event schema
with source_events as (
    select
        event_id,
        user_id,
        event_timestamp,
        event_name,
        event_properties,
        session_id,
        platform,
        country,
        created_at
    from {{ source('raw', 'events') }}
    where event_timestamp is not null
      and user_id is not null
)

select * from source_events

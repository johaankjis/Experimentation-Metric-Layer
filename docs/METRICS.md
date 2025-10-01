# Canonical Metrics Documentation

## Overview

This document describes the canonical metric definitions in the experimentation layer. All metrics follow strict data contracts with schema tests to ensure consistency.

---

## Engagement Metrics

### Daily Active Users (DAU)

**Model:** `fact_dau`

**Definition:** A user is counted as a Daily Active User (DAU) if they have at least one event on a given day.

**Schema:**
- `activity_date` - Date of activity
- `user_id` - User identifier
- `event_count` - Number of events for user on this day
- `session_count` - Number of sessions for user on this day
- `is_active` - Binary flag (always 1 for DAU)
- `metric_value` - Event count (used for experimentation)

**Tests:**
- Not null: activity_date, user_id, event_count, is_active, metric_value
- Unique combination: (activity_date, user_id)
- Accepted values: is_active in [1]

**Usage:**
```sql
SELECT 
    activity_date,
    COUNT(DISTINCT user_id) as dau
FROM fact_dau
GROUP BY 1
ORDER BY 1 DESC;
```

---

### Weekly Active Users (WAU)

**Model:** `fact_wau`

**Definition:** A user is counted as a Weekly Active User (WAU) if they have at least one event during a calendar week (Sunday-Saturday).

**Schema:**
- `week_start` - Start of the week (Sunday)
- `user_id` - User identifier
- `event_count` - Number of events for user this week
- `active_days` - Number of days user was active this week
- `session_count` - Number of sessions for user this week
- `is_active` - Binary flag (always 1 for WAU)
- `metric_value` - Event count (used for experimentation)

**Usage:**
```sql
SELECT 
    week_start,
    COUNT(DISTINCT user_id) as wau
FROM fact_wau
GROUP BY 1
ORDER BY 1 DESC;
```

---

### Monthly Active Users (MAU)

**Model:** `fact_mau`

**Definition:** A user is counted as a Monthly Active User (MAU) if they have at least one event during a calendar month.

**Schema:**
- `month_start` - Start of the month (1st day)
- `user_id` - User identifier
- `event_count` - Number of events for user this month
- `active_days` - Number of days user was active this month
- `session_count` - Number of sessions for user this month
- `is_active` - Binary flag (always 1 for MAU)
- `metric_value` - Event count (used for experimentation)

**Usage:**
```sql
SELECT 
    month_start,
    COUNT(DISTINCT user_id) as mau
FROM fact_mau
GROUP BY 1
ORDER BY 1 DESC;
```

---

## Product Metrics

### Activation

**Model:** `fact_activation`

**Definition:** A user is activated if they complete at least N actions (default: 3) within X days (default: 7) of signup.

**Configurable Parameters:**
- `activation_actions_count` - Number of actions required (default: 3)
- `activation_days_window` - Days from signup (default: 7)

**Schema:**
- `user_id` - User identifier
- `signup_date` - Date user signed up
- `action_count` - Number of actions in activation window
- `first_action_timestamp` - Timestamp of first action
- `is_activated` - Binary flag (1 if activated, 0 otherwise)
- `metric_value` - Same as is_activated (used for experimentation)

**Tests:**
- Unique: user_id
- Not null: user_id, signup_date, action_count, is_activated
- Accepted values: is_activated in [0, 1]

**Usage:**
```sql
SELECT 
    signup_date,
    AVG(is_activated) as activation_rate,
    COUNT(*) as cohort_size
FROM fact_activation
WHERE signup_date >= CURRENT_DATE - INTERVAL '30' DAY
GROUP BY 1
ORDER BY 1 DESC;
```

---

### Retention

**Model:** `fact_retention`

**Definition:** Tracks whether users return on specific days after signup. Calculates N-day retention cohorts.

**Retention Windows:**
- Day 1 retention
- Day 7 retention
- Day 14 retention
- Day 30 retention

**Schema:**
- `user_id` - User identifier
- `signup_date` - Date user signed up
- `retained_day_1` - Binary flag for day 1 retention
- `retained_day_7` - Binary flag for day 7 retention
- `retained_day_14` - Binary flag for day 14 retention
- `retained_day_30` - Binary flag for day 30 retention
- `metric_value` - Day 7 retention (default metric for experimentation)

**Tests:**
- Unique: user_id
- Not null: user_id, signup_date, all retention flags
- Accepted values: all retention flags in [0, 1]

**Usage:**
```sql
-- Day 7 retention by cohort
SELECT 
    signup_date,
    AVG(retained_day_7) as day_7_retention,
    COUNT(*) as cohort_size
FROM fact_retention
WHERE signup_date >= CURRENT_DATE - INTERVAL '60' DAY
GROUP BY 1
ORDER BY 1 DESC;
```

---

## Session Metrics

### Sessionization

**Model:** `fact_sessions`

**Definition:** Sessions are defined by an idle timeout rule. A new session starts if more than N minutes (default: 30) elapse between consecutive events from the same user.

**Configurable Parameters:**
- `session_idle_timeout_minutes` - Idle timeout in minutes (default: 30)

**Schema:**
- `user_id` - User identifier
- `session_number` - Sequential session number for user
- `session_start` - Timestamp of first event in session
- `session_end` - Timestamp of last event in session
- `event_count` - Number of events in session
- `session_duration_minutes` - Duration of session in minutes
- `metric_value` - Session duration (used for experimentation)

**Tests:**
- Not null: user_id, session_number, session_start, session_end, event_count, session_duration_minutes
- Unique combination: (user_id, session_number)

**Usage:**
```sql
-- Average session duration
SELECT 
    DATE(session_start) as session_date,
    AVG(session_duration_minutes) as avg_duration,
    COUNT(*) as total_sessions
FROM fact_sessions
WHERE session_start >= CURRENT_DATE - INTERVAL '7' DAY
GROUP BY 1
ORDER BY 1 DESC;
```

---

## Using Metrics in Experiments

All metrics expose a `metric_value` column that can be used directly in experiment analysis:

```sql
-- Example: Compare DAU metric across variants
SELECT 
    e.variant,
    AVG(m.metric_value) as avg_metric,
    COUNT(DISTINCT e.user_id) as sample_size
FROM experiment_assignments e
JOIN fact_dau m ON e.user_id = m.user_id
WHERE e.experiment_id = 'exp_001'
GROUP BY 1;
```

Or use the built-in templates:

```sql
-- Run difference-in-means test
{{ experiment_difference_in_means('exp_001', 'fact_dau') }}
```

---

## Customization

To customize metric definitions:

1. Edit the SQL in `models/metrics/`
2. Update variables in `dbt_project.yml`
3. Run `dbt run --models tag:metrics`
4. Validate with `dbt test --models tag:metrics`

---

## Data Quality

All metrics include:
- **Schema tests** - Not null, unique, referential integrity
- **Data tests** - Value ranges, accepted values
- **Anomaly detection** - Automated checks for volume, nulls, distributions

See `tests/data_quality_checks.yml` for details.

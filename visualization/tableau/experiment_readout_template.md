# Tableau Dashboard Template - Experiment Readouts

## Overview

This document describes the recommended Tableau dashboard structure for experiment readouts.

## Data Source Connection

Connect Tableau to your Trino/Presto warehouse:

```
Connection Type: Presto/Trino
Server: your-trino-host.com
Port: 8080
Catalog: hive
Schema: experimentation_prod
```

## Dashboard Sections

### 1. Experiment Overview
- Experiment name and ID
- Hypothesis
- Start/End dates
- Status (Running, Completed, Stopped)
- Owner
- Target metric

**SQL:**
```sql
SELECT *
FROM experimentation.experiment_registry
WHERE experiment_id = [Parameter: Experiment ID]
```

### 2. Sample Size & Balance
- Total users per variant
- Sample ratio
- SRM status (PASS/FAIL/WARNING)

**SQL:**
```sql
SELECT 
    variant,
    COUNT(DISTINCT user_id) as sample_size,
    COUNT(DISTINCT user_id) * 1.0 / SUM(COUNT(DISTINCT user_id)) OVER () as sample_ratio
FROM experimentation.experiment_assignments
WHERE experiment_id = [Parameter: Experiment ID]
GROUP BY 1
```

### 3. Primary Metric Results
- Control vs Treatment mean
- Absolute lift
- Relative lift (%)
- 95% Confidence Interval
- P-value
- Statistical significance

**Calculated Fields:**
```
Lift = [Treatment Mean] - [Control Mean]
Relative Lift % = ([Treatment Mean] - [Control Mean]) / [Control Mean] * 100
Significant = IF [P-Value] < 0.05 THEN "✓ Significant" ELSE "Not Significant" END
```

### 4. Guardrail Metrics
- Sample Ratio Mismatch status
- Outlier detection status
- Null rate status
- Overall health status

**SQL:**
```sql
SELECT *
FROM (
    -- Use experiment_guardrails macro output
    {{ experiment_guardrails('[Parameter: Experiment ID]') }}
)
```

### 5. Secondary Metrics
Table showing results for multiple metrics:
- DAU
- Activation
- Retention
- Session Duration

Each with:
- Mean per variant
- Lift
- CI
- Significance

### 6. Time Series
Line chart showing metric evolution over time:
- X-axis: Date
- Y-axis: Metric value
- Color: Variant
- Shows if effect is stable over time

**SQL:**
```sql
SELECT 
    date(e.assigned_at) as experiment_date,
    e.variant,
    AVG(m.metric_value) as avg_metric
FROM experimentation.experiment_assignments e
JOIN experimentation.fact_dau m 
    ON e.user_id = m.user_id 
    AND m.activity_date >= date(e.assigned_at)
WHERE e.experiment_id = [Parameter: Experiment ID]
GROUP BY 1, 2
ORDER BY 1, 2
```

### 7. Distribution Comparison
Histogram comparing metric distributions:
- Separate histograms for control vs treatment
- Shows if distributions differ beyond just mean

### 8. Segment Analysis (Optional)
Break down results by segments:
- Country
- Platform
- User cohort
- Previous engagement level

## Color Palette

Use consistent colors:
- Control: Gray (#808080)
- Treatment: Blue (#1f77b4)
- Significant Positive: Green (#2ca02c)
- Significant Negative: Red (#d62728)
- Not Significant: Light Gray (#d3d3d3)

## Key Metrics to Display

1. **Sample Size**: Total users per variant
2. **Statistical Power**: Calculated based on observed variance
3. **Lift**: Absolute and relative
4. **Confidence Interval**: 95% CI shown as error bars
5. **P-value**: With visual indicator of significance
6. **Runtime**: Days since start
7. **Guardrail Status**: Overall health indicator

## Formatting Guidelines

- Use large, bold numbers for key metrics
- Show confidence intervals as ranges or error bars
- Use color coding for significance
- Include context (e.g., baseline values, historical trends)
- Add annotations for important observations

## Example Layout

```
┌─────────────────────────────────────────────────┐
│  Experiment: Homepage CTA Color Test (exp_001)  │
│  Status: Completed | Owner: pm-jane             │
│  Runtime: 14 days | Target: DAU                 │
└─────────────────────────────────────────────────┘

┌──────────────────────┐  ┌──────────────────────┐
│  Sample Size         │  │  Guardrails          │
│  Control: 10,234     │  │  ✓ SRM Check         │
│  Treatment: 10,156   │  │  ✓ Outliers          │
│  Ratio: 50.2% / 49.8%│  │  ✓ Null Rate         │
│  ✓ Balanced          │  │  Overall: PASS       │
└──────────────────────┘  └──────────────────────┘

┌─────────────────────────────────────────────────┐
│  Primary Metric: DAU                            │
│                                                 │
│  Control Mean:    5.23 events/user              │
│  Treatment Mean:  5.67 events/user              │
│                                                 │
│  Absolute Lift:   +0.44 events/user             │
│  Relative Lift:   +8.4%                         │
│                                                 │
│  95% CI:          [+0.21, +0.67]                │
│  P-value:         < 0.01                        │
│  ✓ Statistically Significant                    │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│  Secondary Metrics                              │
│  ┌────────┬─────────┬────────┬────────┬────┐  │
│  │ Metric │ Control │Treatment│ Lift % │Sig?│  │
│  ├────────┼─────────┼────────┼────────┼────┤  │
│  │Activ.  │  22.1%  │  23.8% │ +7.7%  │ ✓  │  │
│  │Ret D7  │  31.2%  │  32.1% │ +2.9%  │ ✗  │  │
│  │Session │  8.3min │  8.5min│ +2.4%  │ ✗  │  │
│  └────────┴─────────┴────────┴────────┴────┘  │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│  Metric Over Time                               │
│  [Line chart showing DAU trend by variant]      │
└─────────────────────────────────────────────────┘
```

## Parameters

Create parameters for:
- Experiment ID (dropdown with all experiments)
- Date Range
- Confidence Level (default: 95%)
- Segment Filter (optional)

## Interactivity

- Click experiment from list to view details
- Hover for exact values and CIs
- Filter by date range to see evolution
- Drill down by segment

## Refresh Schedule

- Development: Manual refresh
- Production: Daily refresh at 9 AM
- Near-real-time: Every 4 hours (if needed)

## Access Control

- Data Science team: Full access
- Product Managers: Read access
- Engineering: Read access
- Executives: Dashboard access only

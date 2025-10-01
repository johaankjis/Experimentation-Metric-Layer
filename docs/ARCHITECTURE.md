# Architecture Overview

## System Design

The Experimentation Metric Layer follows a **layered architecture** pattern:

```
┌─────────────────────────────────────────────────────┐
│            Application Layer                        │
│  (BI Tools, Dashboards, Notebooks)                  │
└─────────────────────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────────┐
│         Presentation Layer                          │
│  • experiment_summary                               │
│  • experiment_results                               │
└─────────────────────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────────┐
│           Business Logic Layer                      │
│  • metric_calculations                              │
│  • statistical analysis                             │
│  • anomaly detection                                │
└─────────────────────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────────┐
│         Reference Data Layer                        │
│  • metric_definitions                               │
│  • experiment_assignments                           │
└─────────────────────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────────┐
│            Raw Data Layer                           │
│  • experiments (source)                             │
│  • user_events (source)                             │
│  • experiment_assignments (source)                  │
└─────────────────────────────────────────────────────┘
```

## Data Flow

### 1. Metric Definition Phase
```
metric_definitions.sql
  ↓
[Canonical metric catalog is created]
  ↓
Used by all downstream models
```

### 2. Experiment Execution Phase
```
Raw experiment data
  ↓
experiment_assignments (who's in what variant?)
  ↓
metric_calculations (what did they do?)
  ↓
Statistical analysis
```

### 3. Analysis Phase
```
metric_calculations + experiment_assignments
  ↓
experiment_results (statistical tests)
  ↓
experiment_summary (ship decision)
```

### 4. Quality Assurance Phase
```
experiment_assignments
  ↓
sample_ratio_mismatch (SRM check)

metric_calculations
  ↓
metric_anomalies (outlier detection)
```

## Key Design Decisions

### 1. **SQL-Native Approach**
- All logic implemented in SQL for transparency
- No black-box calculations
- Easy to audit and debug
- Works with existing BI tools

### 2. **Canonical Metrics**
- Single source of truth for metric definitions
- Prevents disputes about "how metrics are calculated"
- Ensures consistency across experiments
- Easy to version and track changes

### 3. **Separation of Concerns**
- **Metrics layer**: What to measure
- **Experiments layer**: How to analyze
- **Anomaly detection layer**: Quality checks
- Each layer can be developed independently

### 4. **Materialization Strategy**
- **Tables**: For expensive computations (experiment_results, metric_calculations)
- **Views**: For real-time monitoring (anomaly detection)
- **Incremental models**: For very large datasets (can be added)

### 5. **Statistical Rigor**
- Confidence intervals included
- Multiple testing considerations
- Guardrail metrics to prevent negative impacts
- SRM detection as a critical quality gate

## Technology Stack

### Core Components
- **Trino/Presto**: Query engine (chosen for scale and SQL compatibility)
- **dbt**: Transformation framework (provides version control, testing, documentation)
- **SQL**: Primary implementation language

### Why Trino/Presto?
- Handles large-scale data efficiently
- Rich SQL feature set (window functions, statistical functions)
- Federation capabilities (can query multiple data sources)
- Industry-proven at companies like Meta, Netflix, Airbnb

### Why dbt?
- Version control for SQL transformations
- Built-in testing framework
- Documentation generation
- Dependency management (DAG)
- Incremental builds

## Integration Points

### Upstream Systems
- **Experiment Assignment Service**: Provides user-variant mappings
- **Event Tracking**: Captures user behavior
- **Feature Flags**: Controls experiment rollout

### Downstream Systems
- **BI Tools**: Tableau, Looker, Metabase
- **Notebooks**: Jupyter, Databricks
- **Alerting**: Slack, PagerDuty
- **Decision Systems**: Automated ship/no-ship

# Experimentation & Metric Layer (A/B Testing in SQL)

## Overview
A lightweight, SQL-native experimentation platform that standardizes **metrics**, accelerates **A/B test analysis**, and reduces **data disputes**.  
Built on Presto/Trino + dbt, the layer provides canonical metric definitions, reusable experiment templates, and automated anomaly checks to support **faster, more reliable product experimentation**.

---

## 🎯 Key Features

### 1. **Canonical Metric Definitions**
- Standardized metrics shared across all experiments
- Single source of truth for metric calculations
- Support for ratio, count, and average metrics
- Guardrail metrics to protect user experience

### 2. **Reusable Experiment Templates**
- Statistical analysis framework (mean, lift, significance)
- Confidence intervals and p-values
- Automated experiment summaries with ship/no-ship recommendations
- Sample size and statistical power calculations

### 3. **Automated Anomaly Detection**
- **Sample Ratio Mismatch (SRM)** detection using chi-square tests
- **Metric anomaly detection** comparing against historical baselines
- Z-score based outlier identification
- Real-time quality monitoring

---

## 📁 Project Structure

```
experimentation-metric-layer/
├── dbt_project.yml              # dbt project configuration
├── profiles.yml                 # Database connection profiles
├── models/
│   ├── sources.yml              # Raw data source definitions
│   ├── metrics/
│   │   ├── schema.yml           # Metric model documentation
│   │   ├── metric_definitions.sql     # Canonical metric catalog
│   │   └── metric_calculations.sql    # Per-user metric values
│   ├── experiments/
│   │   ├── schema.yml           # Experiment model documentation
│   │   ├── experiment_assignments.sql # User-variant assignments
│   │   ├── experiment_results.sql     # Statistical analysis
│   │   └── experiment_summary.sql     # High-level overview
│   └── anomaly_detection/
│       ├── schema.yml           # Quality check documentation
│       ├── sample_ratio_mismatch.sql  # SRM detection
│       └── metric_anomalies.sql       # Metric anomaly detection
├── macros/
│   └── experiment_macros.sql    # Reusable SQL functions
└── analyses/
    └── example_experiment_analysis.sql # Complete analysis example
```

---

## 🚀 Getting Started

### Prerequisites
- **Trino/Presto** database (v400+)
- **dbt** (v1.0+)
- Python 3.7+ (for dbt)

### Installation

1. **Clone the repository:**
```bash
git clone https://github.com/johaankjis/Experimentation-Metric-Layer.git
cd Experimentation-Metric-Layer
```

2. **Install dbt:**
```bash
pip install dbt-trino
```

3. **Configure your database connection:**
Edit `profiles.yml` with your Trino/Presto credentials:
```yaml
experimentation_metric_layer:
  target: dev
  outputs:
    dev:
      type: trino
      host: your-trino-host
      port: 8080
      database: experimentation
      schema: public
```

4. **Run dbt models:**
```bash
dbt deps
dbt run
dbt test
```

---

## 📊 Core Models

### Metrics Layer

#### `metric_definitions`
Canonical catalog of all metrics used in experiments.

**Key Columns:**
- `metric_id`: Unique identifier (e.g., 'conversion_rate')
- `metric_name`: Human-readable name
- `metric_type`: Type of metric (ratio, count, average)
- `numerator_sql`: SQL expression for numerator
- `denominator_sql`: SQL expression for denominator (for ratios)
- `is_guardrail`: Flag for guardrail metrics

**Example Metrics:**
- Conversion Rate
- Revenue Per User
- Sessions Per User
- Error Rate (guardrail)
- Page Load Time (guardrail)

#### `metric_calculations`
Calculated metric values for each user in each experiment variant.

---

### Experiments Layer

#### `experiment_assignments`
Tracks which users are assigned to which experiment variants.

#### `experiment_results`
Statistical analysis of experiments:
- Mean values (control vs treatment)
- Absolute and relative lift
- Statistical significance (p-values, z-scores)
- Confidence intervals

#### `experiment_summary`
High-level experiment overview:
- Sample sizes
- Primary metric results
- Guardrail metric status
- Ship/no-ship recommendation

---

### Anomaly Detection Layer

#### `sample_ratio_mismatch`
Detects Sample Ratio Mismatch (SRM) issues using chi-square tests.

**What is SRM?**
SRM occurs when the actual ratio of users in experiment variants differs significantly from the expected ratio. This can indicate:
- Randomization problems
- Data pipeline issues
- Selection bias

**Detection:**
- Uses chi-square test with p < 0.001 threshold
- Flags experiments with critical SRM issues

#### `metric_anomalies`
Identifies unusual metric values by comparing against historical baselines.

**Detection Method:**
- Calculates z-scores against historical mean/stddev
- Flags values more than 3 standard deviations from baseline
- Provides severity classification (critical, high, medium, normal)

---

## 🛠️ SQL Macros

Reusable functions for common experiment operations:

### `calculate_relative_lift(treatment, control)`
Calculates percentage lift of treatment over control.

### `calculate_confidence_interval(mean, stddev, n, confidence_level)`
Calculates confidence interval for a metric.

### `calculate_required_sample_size(baseline, mde, alpha, power)`
Determines minimum sample size needed for experiment.

### `flag_outliers(value_column, threshold)`
Flags outlier values using z-score method.

### `get_experiment_date_filter(start_date, end_date)`
Standard date filter for experiment analysis (excludes first/last day).

---

## 📖 Usage Example

### Running a Complete Experiment Analysis

```sql
-- 1. Check for quality issues
SELECT * FROM sample_ratio_mismatch WHERE experiment_id = 'exp_123';
SELECT * FROM metric_anomalies WHERE experiment_id = 'exp_123' AND is_anomaly = true;

-- 2. View experiment summary
SELECT * FROM experiment_summary WHERE experiment_id = 'exp_123';

-- 3. Analyze all metrics
SELECT 
    m.metric_name,
    m.is_guardrail,
    r.control_mean,
    r.treatment_mean,
    r.relative_lift_pct,
    r.is_significant,
    r.result_direction
FROM experiment_results r
JOIN metric_definitions m ON r.metric_id = m.metric_id
WHERE r.experiment_id = 'exp_123'
ORDER BY m.is_guardrail DESC, r.is_significant DESC;

-- 4. Get ship decision
SELECT 
    experiment_name,
    recommendation,
    primary_lift_pct,
    failed_guardrails
FROM experiment_summary 
WHERE experiment_id = 'exp_123';
```

See `analyses/example_experiment_analysis.sql` for a complete end-to-end example.

---

## 📋 Data Requirements

### Required Raw Tables

Your data warehouse should contain these source tables:

#### `raw.experiments`
```sql
CREATE TABLE raw.experiments (
    experiment_id VARCHAR,
    experiment_name VARCHAR,
    start_date DATE,
    end_date DATE,
    primary_metric_id VARCHAR,
    hypothesis TEXT,
    control_ratio DOUBLE,    -- Default 0.5
    treatment_ratio DOUBLE   -- Default 0.5
);
```

#### `raw.experiment_assignments`
```sql
CREATE TABLE raw.experiment_assignments (
    experiment_id VARCHAR,
    user_id VARCHAR,
    variant_id VARCHAR,           -- 'control' or 'treatment'
    assignment_timestamp TIMESTAMP,
    user_cohort VARCHAR,
    assignment_method VARCHAR,
    assignment_hash VARCHAR
);
```

#### `raw.user_events`
```sql
CREATE TABLE raw.user_events (
    event_id VARCHAR,
    user_id VARCHAR,
    event_timestamp TIMESTAMP,
    event_type VARCHAR,
    session_id VARCHAR,
    converted BOOLEAN,
    revenue DOUBLE,
    error_occurred BOOLEAN,
    page_load_time_ms INTEGER
);
```

---

## 🧪 Testing

Run dbt tests to validate data quality:

```bash
# Run all tests
dbt test

# Run tests for specific model
dbt test --select metric_definitions

# Run tests for specific tag
dbt test --select tag:metrics
```

---

## 🎓 Best Practices

### 1. **Always Check for SRM**
Before analyzing results, verify no Sample Ratio Mismatch exists:
```sql
SELECT * FROM sample_ratio_mismatch WHERE has_srm = true;
```

### 2. **Monitor Guardrail Metrics**
Never ship an experiment with failed guardrails:
```sql
SELECT * FROM experiment_summary WHERE failed_guardrails > 0;
```

### 3. **Use Sufficient Sample Sizes**
Calculate required sample size before launching:
```sql
SELECT {{ calculate_required_sample_size(0.15, 0.02, 0.05, 0.80) }} AS min_sample_size;
```

### 4. **Exclude Ramp-up and Ramp-down Days**
The date filter macro automatically excludes first/last day to avoid partial data.

### 5. **Define Metrics Once**
Add all metrics to `metric_definitions.sql` for consistency across experiments.

---

## 🔧 Customization

### Adding New Metrics

1. Add metric definition to `models/metrics/metric_definitions.sql`:
```sql
UNION ALL
SELECT
    'my_new_metric' AS metric_id,
    'My New Metric' AS metric_name,
    'ratio' AS metric_type,
    'COUNT(DISTINCT conversions)' AS numerator_sql,
    'COUNT(DISTINCT users)' AS denominator_sql,
    false AS is_guardrail,
    'Description of my metric' AS description
```

2. Update metric calculation logic in `models/metrics/metric_calculations.sql`

3. Run dbt:
```bash
dbt run --select metric_definitions metric_calculations+
```

### Adding New Statistical Tests

Create new models in `models/anomaly_detection/` following the existing patterns.

---

## 📈 Performance Optimization

- Models are materialized as **tables** for fast query performance
- Anomaly detection models use **views** for real-time monitoring
- Use partitioning on large tables (by date or experiment_id)
- Consider incremental models for very large datasets

---

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

---

## 📝 License

This project is licensed under the MIT License.

---

## 🙏 Acknowledgments

Built on industry best practices from:
- [Evan Miller's A/B Testing Calculator](https://www.evanmiller.org/ab-testing/)
- [Optimizely's Stats Engine](https://www.optimizely.com/insights/blog/stats-engine/)
- [Netflix's Experimentation Platform](https://netflixtechblog.com/its-all-a-bout-testing-the-netflix-experimentation-platform-4e1ca458c15)

---

## 📞 Support

For questions or issues:
- Open an issue on GitHub
- Check existing documentation in `/analyses`
- Review dbt model documentation with `dbt docs generate && dbt docs serve`

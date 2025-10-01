# Experimentation & Metric Layer

<p align="center">
  <strong>A SQL-native, transparent, and scalable framework for A/B testing and canonical metric definitions</strong>
</p>

<p align="center">
  <a href="#key-features">Features</a> •
  <a href="#quick-start">Quick Start</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#documentation">Documentation</a> •
  <a href="#contributing">Contributing</a>
</p>

---

## 📊 Overview

The **Experimentation & Metric Layer** is a comprehensive data framework built on **dbt** and **Trino/Presto** that provides:

1. **Canonical Metric Definitions** - Single source of truth for business metrics
2. **Experiment Analysis Tools** - Statistical testing templates for A/B experiments
3. **Quality Assurance** - Automated guardrails and anomaly detection
4. **Transparent SQL** - No black-box calculations, everything is auditable

### Why This Framework?

```
┌─────────────────────────────────────────────────────────────┐
│  Problem: Metric disputes, inconsistent analyses,          │
│           lack of statistical rigor in experimentation     │
└─────────────────────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Solution: Centralized metric layer + experiment templates │
│            with built-in statistical testing               │
└─────────────────────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Benefits:                                                  │
│  ✓ Consistent metrics across teams                         │
│  ✓ Faster experiment analysis                              │
│  ✓ Automated quality checks                                │
│  ✓ Transparent, auditable SQL                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Key Features

### 1. Canonical Metrics
Define metrics once, use everywhere:
- **Daily/Weekly/Monthly Active Users (DAU/WAU/MAU)**
- **Activation Rate**
- **Retention Cohorts**
- **Session Metrics**
- Custom metrics for your product

### 2. Statistical Analysis Templates
SQL macros for rigorous A/B testing:
- **Difference-in-Means Tests** (t-tests, Welch's test)
- **CUPED** (Variance reduction for faster experiments)
- **Guardrail Checks** (SRM detection, outlier detection)
- **Confidence Intervals** and p-values

### 3. Quality Assurance
Automated checks to ensure experiment validity:
- Sample Ratio Mismatch (SRM) detection
- Outlier and anomaly detection
- Data quality tests
- Guardrail metrics

### 4. Production-Ready Infrastructure
- dbt models with version control
- Automated testing framework
- Documentation generation
- Airflow orchestration for scheduled reports

---

## 🏗️ Architecture

### High-Level System Design

```
┌──────────────────────────────────────────────────────────────────┐
│                     APPLICATION LAYER                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Tableau    │  │   Looker     │  │   Jupyter    │          │
│  │  Dashboards  │  │  Dashboards  │  │  Notebooks   │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└──────────────────────────────────────────────────────────────────┘
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                             │
│  ┌───────────────────────┐  ┌──────────────────────────┐       │
│  │ experiment_summary    │  │  experiment_results      │       │
│  │ (Ship/No-Ship)        │  │  (Statistical Tests)     │       │
│  └───────────────────────┘  └──────────────────────────┘       │
└──────────────────────────────────────────────────────────────────┘
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│                  BUSINESS LOGIC LAYER                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ Metric          │  │ Statistical     │  │ Anomaly         │ │
│  │ Calculations    │  │ Analysis        │  │ Detection       │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│                  REFERENCE DATA LAYER                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ Metric          │  │ Experiment      │  │ Experiment      │ │
│  │ Definitions     │  │ Registry        │  │ Assignments     │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│                     RAW DATA LAYER                               │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ user_events     │  │ experiments     │  │ experiment_     │ │
│  │ (Event Stream)  │  │ (Metadata)      │  │ assignments     │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

### Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ STEP 1: METRIC DEFINITION                                   │
│                                                             │
│  Raw Events → stg_events → fact_dau, fact_activation, etc. │
│                              ↓                              │
│                    Canonical Metric Catalog                 │
└─────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 2: EXPERIMENT SETUP                                    │
│                                                             │
│  experiment_registry  +  experiment_assignments             │
│  (What to test)          (Who sees what)                    │
└─────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 3: DATA COLLECTION                                     │
│                                                             │
│  Users interact with variants → Events captured             │
│                                    ↓                        │
│              Joined with metric definitions                 │
└─────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 4: STATISTICAL ANALYSIS                                │
│                                                             │
│  ┌──────────────────┐  ┌──────────────────┐               │
│  │ Difference-in-   │  │ Quality Checks   │               │
│  │ Means Test       │  │ (SRM, Outliers)  │               │
│  └──────────────────┘  └──────────────────┘               │
│           ↓                      ↓                          │
│     experiment_results    guardrail_metrics                │
└─────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 5: DECISION MAKING                                     │
│                                                             │
│  experiment_summary → Ship/No-Ship Recommendation           │
│                                                             │
│  Based on: Primary metric lift, Guardrails, Quality checks │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚀 Quick Start

### Prerequisites

- Trino/Presto database access
- Python 3.7+
- dbt-trino installed

### Installation (5 minutes)

```bash
# 1. Install dbt
pip install dbt-trino

# 2. Clone the repository
git clone https://github.com/johaankjis/Experimentation-Metric-Layer.git
cd Experimentation-Metric-Layer

# 3. Configure database connection
cp profiles.yml.example profiles.yml
# Edit profiles.yml with your Trino credentials

# 4. Set up source tables (see Setup Guide)
# Create raw.user_events, raw.experiments, raw.experiment_assignments

# 5. Run dbt
cd dbt_project
dbt deps
dbt run
dbt test
```

### Your First Experiment Analysis

```sql
-- 1. Register your experiment
INSERT INTO experiment_registry VALUES (
    'exp_001',                          -- experiment_id
    'Homepage CTA Test',                -- experiment_name
    'Green button increases clicks',    -- hypothesis
    '2024-01-01',                       -- start_date
    '2024-01-14',                       -- end_date
    'running',                          -- status
    'pm-jane',                          -- owner
    'fact_dau',                         -- target_metric
    0.05,                               -- min_detectable_effect (5%)
    0.80,                               -- statistical_power (80%)
    10000                               -- sample_size_per_variant
);

-- 2. Run statistical analysis
{{ experiment_difference_in_means('exp_001', 'fact_dau') }}

-- 3. Check for quality issues
SELECT * FROM sample_ratio_mismatch 
WHERE experiment_id = 'exp_001';

-- 4. View summary and recommendation
SELECT * FROM experiment_summary 
WHERE experiment_id = 'exp_001';
```

**Output Example:**
```
┌─────────────┬──────────────┬──────────────┬──────────────┬──────────┐
│ Metric      │ Control Mean │ Treatment    │ Relative     │ P-value  │
│             │              │ Mean         │ Lift         │          │
├─────────────┼──────────────┼──────────────┼──────────────┼──────────┤
│ DAU         │ 5.23         │ 5.67         │ +8.4%        │ < 0.01   │
│             │              │              │ [+0.21, +0.67│          │
│             │              │              │ 95% CI]      │          │
└─────────────┴──────────────┴──────────────┴──────────────┴──────────┘

Recommendation: SHIP ✓
- Primary metric shows significant positive lift
- All guardrails passed
- No SRM detected
```

---

## 📁 Repository Structure

```
experimentation-metric-layer/
│
├── dbt_project/                    # Main dbt project
│   ├── models/
│   │   ├── metrics/                # Canonical metric definitions
│   │   │   ├── fact_dau.sql       # Daily Active Users
│   │   │   ├── fact_activation.sql # User activation
│   │   │   ├── fact_retention.sql  # Retention cohorts
│   │   │   └── fact_sessions.sql   # Session metrics
│   │   │
│   │   ├── experiments/            # Experiment analysis models
│   │   │   ├── experiment_assignments.sql
│   │   │   ├── experiment_registry.sql
│   │   │   └── experiment_results.sql
│   │   │
│   │   └── staging/                # Staging models
│   │       └── stg_events.sql      # Clean event data
│   │
│   ├── macros/                     # SQL macros for analysis
│   │   ├── experiment_difference_in_means.sql
│   │   ├── experiment_cuped.sql
│   │   └── experiment_guardrails.sql
│   │
│   ├── analyses/                   # Example queries
│   │   └── example_experiment_analysis.sql
│   │
│   └── tests/                      # Data quality tests
│       └── data_quality_checks.yml
│
├── airflow/                        # Orchestration
│   └── dags/
│       └── experiment_reporting_dag.py
│
├── docs/                           # Detailed documentation
│   ├── QUICKSTART.md              # 15-minute setup guide
│   ├── ARCHITECTURE.md            # System design details
│   ├── EXPERIMENTS.md             # Experiment workflow guide
│   ├── METRICS.md                 # Metric definitions
│   └── SETUP.md                   # Installation instructions
│
├── visualization/                  # BI templates
│   └── tableau/
│       └── experiment_readout_template.md
│
└── README.md                      # This file
```

---

## 🔬 How It Works

### 1. Canonical Metrics Layer

The foundation of the system is a set of **canonical metric definitions** that serve as the single source of truth:

```
┌──────────────────────────────────────────────────────────────┐
│ CANONICAL METRICS                                            │
│                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   DAU       │  │ Activation  │  │ Retention   │        │
│  │             │  │             │  │             │        │
│  │ Definition: │  │ Definition: │  │ Definition: │        │
│  │ Users with  │  │ Users who   │  │ Users who   │        │
│  │ ≥1 event    │  │ completed   │  │ returned on │        │
│  │ per day     │  │ 3 key       │  │ Day 7       │        │
│  │             │  │ actions     │  │             │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
│                                                              │
│  All metrics expose a standard 'metric_value' column        │
│  for use in experiment analysis                             │
└──────────────────────────────────────────────────────────────┘
```

**Example: DAU Metric Definition**
```sql
-- models/metrics/fact_dau.sql
with daily_activity as (
    select
        user_id,
        date(event_timestamp) as activity_date,
        count(distinct event_id) as event_count
    from {{ ref('stg_events') }}
    group by 1, 2
)

select
    activity_date,
    user_id,
    event_count,
    1 as is_active,
    event_count as metric_value  -- Standard column for experiments
from daily_activity
```

### 2. Experiment Workflow

```
┌────────────────────────────────────────────────────────────────┐
│ EXPERIMENT LIFECYCLE                                           │
│                                                                │
│  1. DEFINE                                                     │
│     Register experiment in experiment_registry                 │
│     ↓                                                          │
│  2. ASSIGN                                                     │
│     Populate experiment_assignments (users → variants)         │
│     ↓                                                          │
│  3. COLLECT                                                    │
│     Users generate events during experiment                    │
│     ↓                                                          │
│  4. ANALYZE                                                    │
│     Run statistical tests using SQL macros                     │
│     ↓                                                          │
│  5. VALIDATE                                                   │
│     Check guardrails and quality metrics                       │
│     ↓                                                          │
│  6. DECIDE                                                     │
│     Ship/No-Ship based on experiment_summary                   │
└────────────────────────────────────────────────────────────────┘
```

### 3. Statistical Analysis

The framework provides SQL macros that implement rigorous statistical tests:

#### Difference-in-Means Test

```
┌─────────────────────────────────────────────────────────────┐
│ STATISTICAL TESTING PROCESS                                 │
│                                                             │
│  Inputs:                                                    │
│  • experiment_assignments (who's in control vs treatment)   │
│  • metric_values (what did they do)                         │
│                                                             │
│  ┌───────────┐              ┌───────────┐                  │
│  │ Control   │              │ Treatment │                  │
│  │ Group     │              │ Group     │                  │
│  │           │              │           │                  │
│  │ n = 10K   │              │ n = 10K   │                  │
│  │ μ = 5.23  │              │ μ = 5.67  │                  │
│  │ σ = 2.1   │              │ σ = 2.3   │                  │
│  └───────────┘              └───────────┘                  │
│        │                          │                         │
│        └──────────┬───────────────┘                         │
│                   ▼                                         │
│          ┌────────────────┐                                 │
│          │ Welch's t-test │                                 │
│          └────────────────┘                                 │
│                   ▼                                         │
│  Outputs:                                                   │
│  • Absolute lift: +0.44                                     │
│  • Relative lift: +8.4%                                     │
│  • 95% CI: [+0.21, +0.67]                                   │
│  • p-value: < 0.01                                          │
│  • Conclusion: Statistically significant ✓                  │
└─────────────────────────────────────────────────────────────┘
```

**Usage:**
```sql
-- Call the macro with experiment ID and metric table
{{ experiment_difference_in_means('exp_001', 'fact_dau') }}
```

#### CUPED (Variance Reduction)

```
┌─────────────────────────────────────────────────────────────┐
│ CUPED: Controlled-experiment Using Pre-Experiment Data      │
│                                                             │
│  Problem: High variance → Need large samples               │
│  Solution: Use pre-experiment data to reduce noise          │
│                                                             │
│  ┌──────────────┐                                           │
│  │ Pre-period   │  User's baseline behavior                 │
│  │ Metric Value │  (before experiment)                      │
│  └──────────────┘                                           │
│         │                                                    │
│         ▼                                                    │
│  ┌──────────────┐                                           │
│  │ Adjusted     │  Y_adjusted = Y - θ(X - E[X])            │
│  │ Metric       │                                           │
│  └──────────────┘                                           │
│         │                                                    │
│         ▼                                                    │
│  ┌──────────────┐                                           │
│  │ Reduced      │  Variance can be 50% lower!               │
│  │ Variance     │  → Faster experiments                     │
│  └──────────────┘                                           │
└─────────────────────────────────────────────────────────────┘
```

### 4. Quality Assurance

#### Sample Ratio Mismatch (SRM) Detection

```
┌─────────────────────────────────────────────────────────────┐
│ SAMPLE RATIO MISMATCH (SRM) CHECK                           │
│                                                             │
│  Expected: 50/50 split between control and treatment        │
│                                                             │
│  ┌─────────────┐           ┌─────────────┐                 │
│  │  Control    │           │ Treatment   │                 │
│  │             │           │             │                 │
│  │  Expected:  │           │  Expected:  │                 │
│  │   50%       │           │   50%       │                 │
│  │  (10,000)   │           │  (10,000)   │                 │
│  └─────────────┘           └─────────────┘                 │
│                                                             │
│  Actual observed:                                           │
│  ┌─────────────┐           ┌─────────────┐                 │
│  │  Control    │           │ Treatment   │                 │
│  │   52%       │           │   48%       │                 │
│  │  (10,400)   │           │  (9,600)    │                 │
│  └─────────────┘           └─────────────┘                 │
│                                                             │
│  Chi-square test:                                           │
│  • p-value = 0.03 (< 0.05)                                  │
│  • Conclusion: SRM detected! ⚠️                             │
│  • Action: Investigate assignment mechanism                 │
└─────────────────────────────────────────────────────────────┘
```

**Why SRM matters:**
- Indicates bias in randomization
- Can invalidate experiment results
- Must be resolved before trusting results

---

## 📊 Example Use Cases

### Use Case 1: Testing a New Feature

```
┌─────────────────────────────────────────────────────────────┐
│ SCENARIO: Testing a new "Quick Search" feature              │
│                                                             │
│  Hypothesis: Quick Search will increase DAU by 5%           │
│                                                             │
│  Setup:                                                     │
│  • Control: Original search                                 │
│  • Treatment: New Quick Search feature                      │
│  • Primary Metric: DAU                                      │
│  • Guardrails: Page load time, error rate                   │
│  • Duration: 14 days                                        │
│  • Sample size: 20K users (10K per variant)                 │
│                                                             │
│  Results after 14 days:                                     │
│  ┌──────────────────┬──────────┬───────────┬──────────┐    │
│  │ Metric           │ Control  │ Treatment │ Lift     │    │
│  ├──────────────────┼──────────┼───────────┼──────────┤    │
│  │ DAU              │ 5.23     │ 5.67      │ +8.4% ✓  │    │
│  │ Page Load (ms)   │ 234      │ 231       │ -1.3% ✓  │    │
│  │ Error Rate       │ 0.8%     │ 0.7%      │ -12.5% ✓ │    │
│  └──────────────────┴──────────┴───────────┴──────────┘    │
│                                                             │
│  Decision: SHIP ✓                                           │
│  • Primary metric exceeded target (+8.4% > +5%)             │
│  • All guardrails passed                                    │
│  • No quality issues detected                               │
└─────────────────────────────────────────────────────────────┘
```

### Use Case 2: Optimizing Onboarding Flow

```
┌─────────────────────────────────────────────────────────────┐
│ SCENARIO: Streamlined onboarding (3 steps → 2 steps)        │
│                                                             │
│  Hypothesis: Fewer steps increases activation               │
│                                                             │
│  Primary Metric: Activation Rate                            │
│  • Definition: Users who complete 3 key actions             │
│                                                             │
│  Results:                                                   │
│  ┌──────────────────┬──────────┬───────────┬──────────┐    │
│  │ Metric           │ Control  │ Treatment │ Lift     │    │
│  ├──────────────────┼──────────┼───────────┼──────────┤    │
│  │ Activation Rate  │ 34.2%    │ 41.7%     │ +21.9% ✓ │    │
│  │ Day 7 Retention  │ 52.1%    │ 54.3%     │ +4.2% ✓  │    │
│  │ Support Tickets  │ 12.3     │ 8.7       │ -29.3% ✓ │    │
│  └──────────────────┴──────────┴───────────┴──────────┘    │
│                                                             │
│  Decision: SHIP ✓                                           │
│  • Massive improvement in activation (+21.9%)               │
│  • Positive impact on retention                             │
│  • Reduced support load (fewer confused users)              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎓 Detailed Guides

### For Analysts
- **[Quick Start Guide](docs/QUICKSTART.md)** - Get up and running in 15 minutes
- **[Experiment Guide](docs/EXPERIMENTS.md)** - Complete workflow for running experiments
- **[Metrics Reference](docs/METRICS.md)** - Canonical metric definitions

### For Engineers
- **[Setup Guide](docs/SETUP.md)** - Installation and configuration
- **[Architecture](docs/ARCHITECTURE.md)** - System design and tech stack
- **[Contributing](CONTRIBUTING.md)** - How to add new metrics and templates

### For Product Managers
- **[Tableau Templates](visualization/tableau/experiment_readout_template.md)** - Dashboard designs
- **[Experiment Examples](analyses/example_experiment_analysis.sql)** - Sample analyses

---

## 🛠️ Technology Stack

```
┌─────────────────────────────────────────────────────────────┐
│ TECHNOLOGY STACK                                            │
│                                                             │
│  Data Warehouse                                             │
│  ┌─────────────────────────────────────────┐               │
│  │ Trino / Presto                          │               │
│  │ • Handles large-scale data              │               │
│  │ • Rich SQL features                     │               │
│  │ • Federation capabilities               │               │
│  └─────────────────────────────────────────┘               │
│                  ▼                                          │
│  Transformation Framework                                   │
│  ┌─────────────────────────────────────────┐               │
│  │ dbt (Data Build Tool)                   │               │
│  │ • Version control for SQL               │               │
│  │ • Dependency management (DAG)           │               │
│  │ • Built-in testing                      │               │
│  │ • Documentation generation              │               │
│  └─────────────────────────────────────────┘               │
│                  ▼                                          │
│  Orchestration                                              │
│  ┌─────────────────────────────────────────┐               │
│  │ Apache Airflow                          │               │
│  │ • Scheduled experiment reporting        │               │
│  │ • Automated quality checks              │               │
│  │ • Slack notifications                   │               │
│  └─────────────────────────────────────────┘               │
│                  ▼                                          │
│  Visualization                                              │
│  ┌─────────────────────────────────────────┐               │
│  │ Tableau / Looker / Metabase             │               │
│  │ • Experiment dashboards                 │               │
│  │ • Metric monitoring                     │               │
│  │ • Automated readouts                    │               │
│  └─────────────────────────────────────────┘               │
└─────────────────────────────────────────────────────────────┘
```

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### Adding a New Metric

```sql
-- 1. Create the metric model
-- models/metrics/fact_your_metric.sql

{{
  config(
    materialized='table',
    tags=['metrics', 'your_metric']
  )
}}

select
    user_id,
    date_key,
    your_calculation as metric_value  -- Standard column name
from {{ ref('stg_events') }}
```

### Adding a New Experiment Template

```sql
-- 2. Create the macro
-- macros/experiment_your_test.sql

{% macro experiment_your_test(experiment_id, metric_table) %}
-- Your statistical test logic here
{% endmacro %}
```

### Testing Your Changes

```bash
# Run specific models
dbt run --models tag:metrics

# Run tests
dbt test --models tag:metrics

# Generate documentation
dbt docs generate
dbt docs serve
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

---

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [QUICKSTART.md](docs/QUICKSTART.md) | 15-minute setup guide |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | System design and patterns |
| [EXPERIMENTS.md](docs/EXPERIMENTS.md) | Experiment workflow guide |
| [METRICS.md](docs/METRICS.md) | Canonical metric definitions |
| [SETUP.md](docs/SETUP.md) | Installation instructions |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution guidelines |

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

This framework is inspired by experimentation platforms at:
- **Airbnb** - ERF (Experiment Reporting Framework)
- **Netflix** - ABtesting.ai
- **Meta** - Planout
- **Uber** - XP (Experimentation Platform)

---

## 💬 Support

- **Issues**: [GitHub Issues](https://github.com/johaankjis/Experimentation-Metric-Layer/issues)
- **Discussions**: [GitHub Discussions](https://github.com/johaankjis/Experimentation-Metric-Layer/discussions)
- **Documentation**: [docs/](docs/)

---

<p align="center">
  <strong>Built with ❤️ for data-driven teams</strong>
</p>

<p align="center">
  <sub>Experimentation & Metric Layer • Making A/B testing transparent and rigorous</sub>
</p>
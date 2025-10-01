# Contributing to Experimentation & Metric Layer

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## How to Contribute

### Reporting Issues

- Use GitHub Issues to report bugs or suggest features
- Include clear description of the problem or suggestion
- Provide example SQL queries or dbt models if relevant
- Include expected vs. actual behavior for bugs

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for new functionality
5. Run existing tests to ensure nothing breaks
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

### Code Standards

#### dbt Models

- Follow consistent naming conventions:
  - `stg_` prefix for staging models
  - `fact_` prefix for fact tables
  - `dim_` prefix for dimension tables
- Include documentation in schema.yml files
- Add data tests for all models
- Use CTEs for readable, modular SQL
- Add comments for complex logic

Example:
```sql
{{
  config(
    materialized='table',
    tags=['metrics', 'engagement']
  )
}}

-- Daily Active Users metric
-- A user is active if they have at least 1 event

with daily_activity as (
    select
        user_id,
        date(event_timestamp) as activity_date,
        count(*) as event_count
    from {{ ref('stg_events') }}
    group by 1, 2
)

select * from daily_activity
```

#### SQL Macros

- Add comprehensive documentation in comments
- Include usage examples
- Specify input parameters and types
- Document output columns
- Handle edge cases (null values, empty results)

#### Python (Airflow)

- Follow PEP 8 style guide
- Add docstrings to functions
- Include error handling
- Add logging for debugging

### Testing

#### dbt Tests

All new metrics must include:
- Schema tests (not_null, unique, relationships)
- Data tests (accepted_values, custom tests)
- At least one test per model

Run tests:
```bash
cd dbt_project
dbt test
```

#### Integration Tests

For new SQL templates, provide:
- Example input data
- Expected output
- Edge case scenarios

### Documentation

- Update README.md if adding major features
- Update relevant documentation in `docs/`
- Add inline comments for complex SQL
- Include examples in docstrings

### Adding New Metrics

1. Create SQL file in `models/metrics/`
2. Add schema definition in `models/metrics/schema.yml`
3. Add tests (not_null, uniqueness, etc.)
4. Document in `docs/METRICS.md`
5. Add example usage
6. Run `dbt run` and `dbt test`

### Adding New Templates

1. Create macro in `macros/`
2. Document usage and parameters
3. Add example in `analyses/`
4. Document in `docs/EXPERIMENTS.md`
5. Test with sample data

## Development Setup

```bash
# Clone repository
git clone https://github.com/johaankjis/Experimentation-Metric-Layer.git
cd Experimentation-Metric-Layer

# Install dependencies
pip install dbt-trino

# Configure connection
cd dbt_project
# Edit profiles.yml

# Install dbt packages
dbt deps

# Run models
dbt run

# Run tests
dbt test
```

## Questions?

Open an issue or discussion on GitHub if you have questions!

# Contributing Guide

Thank you for your interest in contributing to the Experimentation Metric Layer!

## Development Setup

### Prerequisites
- Python 3.7+
- Trino/Presto database access
- Git

### Local Development

1. **Clone the repository:**
```bash
git clone https://github.com/johaankjis/Experimentation-Metric-Layer.git
cd Experimentation-Metric-Layer
```

2. **Install dbt:**
```bash
pip install dbt-trino
```

3. **Configure your connection:**
```bash
cp profiles.yml ~/.dbt/profiles.yml
# Edit ~/.dbt/profiles.yml with your credentials
```

4. **Install dependencies:**
```bash
dbt deps
```

5. **Run tests:**
```bash
dbt run
dbt test
```

## Making Changes

### Adding New Metrics

1. **Define the metric** in `models/metrics/metric_definitions.sql`:
```sql
UNION ALL
SELECT
    'your_metric_id' AS metric_id,
    'Your Metric Name' AS metric_name,
    'ratio' AS metric_type,  -- or 'count', 'average'
    'COUNT(...)' AS numerator_sql,
    'COUNT(DISTINCT user_id)' AS denominator_sql,
    false AS is_guardrail,
    'Description of your metric' AS description
```

2. **Update schema documentation** in `models/metrics/schema.yml`

3. **Test your metric:**
```bash
dbt run --select metric_definitions
dbt test --select metric_definitions
```

### Adding New Models

1. **Create your model** in the appropriate directory:
   - `models/metrics/` - Metric definitions and calculations
   - `models/experiments/` - Experiment analysis logic
   - `models/anomaly_detection/` - Quality checks

2. **Add schema documentation** in the corresponding `schema.yml` file

3. **Add tests** in the schema file:
```yaml
columns:
  - name: your_column
    tests:
      - not_null
      - unique
```

4. **Run and test:**
```bash
dbt run --select your_model
dbt test --select your_model
```

### Adding SQL Macros

1. **Create macro** in `macros/`:
```sql
{% macro your_macro_name(param1, param2) %}
    /*
        Description of what your macro does
        
        Args:
            param1: Description
            param2: Description
            
        Returns:
            Description
    */
    -- Your SQL logic here
{% endmacro %}
```

2. **Document usage** in the macro file

3. **Test in a model:**
```sql
SELECT {{ your_macro_name('value1', 'value2') }} AS result
```

## Code Style

### SQL Style

- Use **lowercase** for SQL keywords
- Use **snake_case** for column names
- **Indent** with 4 spaces
- Add **comments** for complex logic
- Use **CTEs** for readability

**Good:**
```sql
WITH user_metrics AS (
    SELECT
        user_id,
        COUNT(*) AS event_count
    FROM events
    WHERE event_date >= CURRENT_DATE - INTERVAL '7' DAY
    GROUP BY 1
)

SELECT
    user_id,
    event_count
FROM user_metrics
WHERE event_count > 10
```

**Avoid:**
```sql
SELECT user_id, COUNT(*) cnt FROM events WHERE event_date>=CURRENT_DATE-INTERVAL '7' DAY AND user_id IS NOT NULL GROUP BY user_id HAVING COUNT(*)>10
```

### dbt Style

- Use **{{ ref() }}** for model references
- Use **{{ source() }}** for raw tables
- Add **config()** at the top of models
- Use **tags** for organization
- Document **all models** in schema.yml

## Testing

### Run All Tests
```bash
dbt test
```

### Run Specific Tests
```bash
# Test a specific model
dbt test --select metric_definitions

# Test by tag
dbt test --select tag:metrics

# Test by type
dbt test --data
```

### Writing Tests

1. **Built-in tests** (in schema.yml):
```yaml
columns:
  - name: metric_id
    tests:
      - unique
      - not_null
```

2. **Custom tests** (in tests/):
```sql
-- tests/test_metric_values_reasonable.sql
SELECT *
FROM {{ ref('metric_calculations') }}
WHERE metric_value < 0 OR metric_value > 1000000
```

## Documentation

### Updating Documentation

- **README.md**: High-level overview and getting started
- **docs/ARCHITECTURE.md**: System design and technical details
- **docs/QUICKSTART.md**: Quick setup guide
- **Schema files**: Model and column descriptions

### Generating dbt Docs

```bash
dbt docs generate
dbt docs serve
```

## Pull Request Process

1. **Create a feature branch:**
```bash
git checkout -b feature/your-feature-name
```

2. **Make your changes**

3. **Run tests:**
```bash
dbt run
dbt test
```

4. **Commit your changes:**
```bash
git add .
git commit -m "Description of your changes"
```

5. **Push to GitHub:**
```bash
git push origin feature/your-feature-name
```

6. **Create a Pull Request:**
   - Describe your changes
   - Reference any related issues
   - Include before/after examples if applicable

### PR Checklist

- [ ] Code follows style guidelines
- [ ] Tests pass (`dbt test`)
- [ ] New models have schema documentation
- [ ] README updated if needed
- [ ] No sensitive data or credentials in code

## Common Tasks

### Adding a New Experiment

1. Insert experiment metadata into `raw.experiments`
2. Populate user assignments in `raw.experiment_assignments`
3. Run dbt models:
```bash
dbt run --select experiment_assignments+
```

### Debugging Failed Tests

1. **Check which test failed:**
```bash
dbt test --store-failures
```

2. **Query the failures:**
```sql
SELECT * FROM <your_schema>_dbt_test__audit.<test_name>
```

3. **Fix the issue and re-run:**
```bash
dbt run --select <model_name>
dbt test --select <model_name>
```

### Performance Optimization

1. **Identify slow models:**
```bash
dbt run --profile perf
```

2. **Optimize with:**
   - Partitioning
   - Bucketing
   - Pre-aggregation
   - Incremental models

3. **Test performance:**
```bash
dbt run --full-refresh
```

## Getting Help

- **Issues**: Open a GitHub issue for bugs or feature requests
- **Discussions**: Use GitHub Discussions for questions
- **Documentation**: Check `dbt docs serve` for model docs

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on the code, not the person
- Help others learn and grow

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

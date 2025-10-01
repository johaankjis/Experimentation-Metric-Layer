{% macro experiment_difference_in_means(experiment_id, metric_table) %}
/*
Difference-in-Means Test (t-test, Welch's test)
Calculates mean, variance, sample size per variant
Returns lift, confidence intervals, and p-values

Usage:
  {{ experiment_difference_in_means('exp_001', 'fact_dau') }}
*/

with variants as (
    select
        e.experiment_id,
        e.variant,
        m.user_id,
        m.metric_value
    from {{ ref('experiment_assignments') }} e
    join {{ ref(metric_table) }} m
      on e.user_id = m.user_id
    where e.experiment_id = '{{ experiment_id }}'
),

variant_stats as (
    select
        experiment_id,
        variant,
        count(distinct user_id) as n,
        avg(metric_value) as mean_value,
        var_samp(metric_value) as variance,
        stddev_samp(metric_value) as std_dev,
        min(metric_value) as min_value,
        max(metric_value) as max_value,
        approx_percentile(metric_value, 0.5) as median_value
    from variants
    group by 1, 2
),

control_treatment as (
    select
        c.experiment_id,
        c.variant as control_variant,
        c.n as control_n,
        c.mean_value as control_mean,
        c.variance as control_variance,
        t.variant as treatment_variant,
        t.n as treatment_n,
        t.mean_value as treatment_mean,
        t.variance as treatment_variance
    from variant_stats c
    cross join variant_stats t
    where c.experiment_id = t.experiment_id
      and c.variant = 'control'
      and t.variant != 'control'
),

statistical_test as (
    select
        experiment_id,
        control_variant,
        treatment_variant,
        control_n,
        treatment_n,
        control_mean,
        treatment_mean,
        -- Absolute and relative lift
        treatment_mean - control_mean as absolute_lift,
        (treatment_mean - control_mean) / nullif(control_mean, 0) as relative_lift_pct,
        -- Standard error (Welch's formula for unequal variances)
        sqrt(
            (control_variance / control_n) + 
            (treatment_variance / treatment_n)
        ) as standard_error,
        -- t-statistic
        (treatment_mean - control_mean) / 
        sqrt(
            (control_variance / control_n) + 
            (treatment_variance / treatment_n)
        ) as t_statistic,
        -- Degrees of freedom (Welch-Satterthwaite formula)
        power(
            (control_variance / control_n) + (treatment_variance / treatment_n),
            2
        ) /
        (
            power(control_variance / control_n, 2) / (control_n - 1) +
            power(treatment_variance / treatment_n, 2) / (treatment_n - 1)
        ) as degrees_of_freedom
    from control_treatment
)

select
    experiment_id,
    control_variant,
    treatment_variant,
    control_n,
    treatment_n,
    control_mean,
    treatment_mean,
    absolute_lift,
    relative_lift_pct * 100 as relative_lift_pct,
    standard_error,
    -- 95% confidence interval
    absolute_lift - (1.96 * standard_error) as ci_lower,
    absolute_lift + (1.96 * standard_error) as ci_upper,
    t_statistic,
    degrees_of_freedom,
    -- Two-tailed p-value approximation (using t-statistic)
    case 
        when abs(t_statistic) > 2.576 then '< 0.01'
        when abs(t_statistic) > 1.96 then '< 0.05'
        when abs(t_statistic) > 1.645 then '< 0.10'
        else '>= 0.10'
    end as p_value_range,
    -- Statistical significance at common thresholds
    case when abs(t_statistic) > 1.96 then true else false end as is_significant_p05,
    case when abs(t_statistic) > 2.576 then true else false end as is_significant_p01
from statistical_test

{% endmacro %}

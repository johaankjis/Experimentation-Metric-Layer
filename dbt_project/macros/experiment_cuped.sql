{% macro experiment_cuped(experiment_id, metric_table, covariate_table) %}
/*
CUPED (Controlled-experiment Using Pre-Experiment Data)
Variance reduction technique using pre-experiment covariates

Usage:
  {{ experiment_cuped('exp_001', 'fact_dau', 'fact_dau_pre_experiment') }}
*/

with variants as (
    select
        e.experiment_id,
        e.variant,
        e.user_id,
        m.metric_value as post_metric
    from {{ ref('experiment_assignments') }} e
    join {{ ref(metric_table) }} m
      on e.user_id = m.user_id
    where e.experiment_id = '{{ experiment_id }}'
),

covariates as (
    select
        user_id,
        metric_value as pre_metric
    from {{ ref(covariate_table) }}
),

combined_data as (
    select
        v.experiment_id,
        v.variant,
        v.user_id,
        v.post_metric,
        coalesce(c.pre_metric, 0) as pre_metric
    from variants v
    left join covariates c
        on v.user_id = c.user_id
),

covariance_calc as (
    select
        experiment_id,
        -- Calculate covariance between pre and post metrics
        covar_samp(pre_metric, post_metric) / var_samp(pre_metric) as theta
    from combined_data
),

adjusted_metrics as (
    select
        cd.experiment_id,
        cd.variant,
        cd.user_id,
        cd.post_metric,
        cd.pre_metric,
        cc.theta,
        -- CUPED-adjusted metric
        cd.post_metric - (cc.theta * (cd.pre_metric - avg(cd.pre_metric) over ())) as adjusted_metric
    from combined_data cd
    cross join covariance_calc cc
),

variant_stats as (
    select
        experiment_id,
        variant,
        count(distinct user_id) as n,
        avg(post_metric) as mean_post,
        avg(adjusted_metric) as mean_adjusted,
        var_samp(post_metric) as variance_post,
        var_samp(adjusted_metric) as variance_adjusted,
        -- Variance reduction
        (var_samp(post_metric) - var_samp(adjusted_metric)) / var_samp(post_metric) as variance_reduction_pct
    from adjusted_metrics
    group by 1, 2
),

control_treatment as (
    select
        c.experiment_id,
        c.variant as control_variant,
        c.n as control_n,
        c.mean_adjusted as control_mean,
        c.variance_adjusted as control_variance,
        c.variance_reduction_pct as control_var_reduction,
        t.variant as treatment_variant,
        t.n as treatment_n,
        t.mean_adjusted as treatment_mean,
        t.variance_adjusted as treatment_variance,
        t.variance_reduction_pct as treatment_var_reduction
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
        -- Lift calculation
        treatment_mean - control_mean as absolute_lift,
        (treatment_mean - control_mean) / nullif(control_mean, 0) as relative_lift_pct,
        -- Standard error with reduced variance
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
        (control_var_reduction + treatment_var_reduction) / 2 as avg_variance_reduction_pct
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
    -- Variance reduction from CUPED
    avg_variance_reduction_pct * 100 as variance_reduction_pct,
    -- Statistical significance
    case when abs(t_statistic) > 1.96 then true else false end as is_significant_p05,
    'CUPED-adjusted' as method
from statistical_test

{% endmacro %}

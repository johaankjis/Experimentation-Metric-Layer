{% macro experiment_guardrails(experiment_id) %}
/*
Experiment Guardrails and Quality Checks
- Sample Ratio Mismatch (SRM) check
- Exposure balance check
- Outlier detection
- Null rate checks

Usage:
  {{ experiment_guardrails('exp_001') }}
*/

with assignments as (
    select
        experiment_id,
        variant,
        user_id,
        assigned_at
    from {{ ref('experiment_assignments') }}
    where experiment_id = '{{ experiment_id }}'
),

-- SRM Check: Are variants balanced as expected?
variant_counts as (
    select
        experiment_id,
        variant,
        count(distinct user_id) as user_count
    from assignments
    group by 1, 2
),

total_users as (
    select
        experiment_id,
        sum(user_count) as total_count
    from variant_counts
    group by 1
),

srm_check as (
    select
        vc.experiment_id,
        vc.variant,
        vc.user_count,
        tu.total_count,
        vc.user_count * 1.0 / tu.total_count as actual_ratio,
        -- Expected ratio (assuming equal allocation)
        1.0 / count(*) over (partition by vc.experiment_id) as expected_ratio,
        -- Chi-square statistic for SRM
        abs(vc.user_count * 1.0 / tu.total_count - 1.0 / count(*) over (partition by vc.experiment_id)) as ratio_deviation
    from variant_counts vc
    join total_users tu
        on vc.experiment_id = tu.experiment_id
),

srm_summary as (
    select
        experiment_id,
        max(ratio_deviation) as max_deviation,
        case 
            when max(ratio_deviation) > 0.05 then 'FAIL'
            when max(ratio_deviation) > 0.02 then 'WARNING'
            else 'PASS'
        end as srm_status
    from srm_check
    group by 1
),

-- Outlier Detection: Flag extreme values
metric_distributions as (
    select
        e.experiment_id,
        e.variant,
        m.user_id,
        m.metric_value,
        avg(m.metric_value) over (partition by e.experiment_id, e.variant) as variant_mean,
        stddev(m.metric_value) over (partition by e.experiment_id, e.variant) as variant_stddev
    from {{ ref('experiment_assignments') }} e
    join {{ ref('fact_dau') }} m
        on e.user_id = m.user_id
    where e.experiment_id = '{{ experiment_id }}'
),

outliers as (
    select
        experiment_id,
        variant,
        count(*) as total_users,
        sum(case 
            when abs(metric_value - variant_mean) > 3 * variant_stddev then 1 
            else 0 
        end) as outlier_count,
        sum(case 
            when abs(metric_value - variant_mean) > 3 * variant_stddev then 1 
            else 0 
        end) * 1.0 / count(*) as outlier_rate
    from metric_distributions
    group by 1, 2
),

outlier_summary as (
    select
        experiment_id,
        max(outlier_rate) as max_outlier_rate,
        case 
            when max(outlier_rate) > 0.05 then 'FAIL'
            when max(outlier_rate) > 0.02 then 'WARNING'
            else 'PASS'
        end as outlier_status
    from outliers
    group by 1
),

-- Null Rate Check
null_checks as (
    select
        e.experiment_id,
        e.variant,
        count(distinct e.user_id) as assigned_users,
        count(distinct m.user_id) as users_with_metric,
        (count(distinct e.user_id) - count(distinct m.user_id)) * 1.0 / count(distinct e.user_id) as null_rate
    from {{ ref('experiment_assignments') }} e
    left join {{ ref('fact_dau') }} m
        on e.user_id = m.user_id
    where e.experiment_id = '{{ experiment_id }}'
    group by 1, 2
),

null_summary as (
    select
        experiment_id,
        max(null_rate) as max_null_rate,
        case 
            when max(null_rate) > 0.50 then 'FAIL'
            when max(null_rate) > 0.30 then 'WARNING'
            else 'PASS'
        end as null_rate_status
    from null_checks
    group by 1
),

-- Combined Guardrails Report
final_report as (
    select
        s.experiment_id,
        s.srm_status,
        s.max_deviation as srm_max_deviation,
        o.outlier_status,
        o.max_outlier_rate,
        n.null_rate_status,
        n.max_null_rate,
        -- Overall health check
        case 
            when s.srm_status = 'FAIL' or o.outlier_status = 'FAIL' or n.null_rate_status = 'FAIL' then 'FAIL'
            when s.srm_status = 'WARNING' or o.outlier_status = 'WARNING' or n.null_rate_status = 'WARNING' then 'WARNING'
            else 'PASS'
        end as overall_status
    from srm_summary s
    cross join outlier_summary o
    cross join null_summary n
    where s.experiment_id = o.experiment_id
      and s.experiment_id = n.experiment_id
)

select
    experiment_id,
    overall_status,
    srm_status,
    srm_max_deviation,
    outlier_status,
    max_outlier_rate,
    null_rate_status,
    max_null_rate,
    case 
        when overall_status = 'FAIL' then 'Experiment has critical quality issues. Do not trust results.'
        when overall_status = 'WARNING' then 'Experiment has quality warnings. Review before making decisions.'
        else 'Experiment quality checks passed.'
    end as recommendation
from final_report

{% endmacro %}

{% macro calculate_relative_lift(treatment_value, control_value) %}
    /*
        Calculate percentage lift of treatment over control
        
        Args:
            treatment_value: Metric value for treatment variant
            control_value: Metric value for control variant
            
        Returns:
            Percentage change (e.g., 15.5 for 15.5% increase)
    */
    CASE 
        WHEN {{ control_value }} = 0 OR {{ control_value }} IS NULL THEN NULL
        ELSE (({{ treatment_value }} - {{ control_value }}) / {{ control_value }}) * 100
    END
{% endmacro %}

{% macro calculate_confidence_interval(mean_value, std_dev, sample_size, confidence_level=1.96) %}
    /*
        Calculate confidence interval for a metric
        
        Args:
            mean_value: Mean of the metric
            std_dev: Standard deviation
            sample_size: Number of observations
            confidence_level: Z-score for desired confidence (default: 1.96 for 95%)
            
        Returns:
            Margin of error for the confidence interval
    */
    {{ confidence_level }} * ({{ std_dev }} / SQRT({{ sample_size }}))
{% endmacro %}

{% macro calculate_required_sample_size(baseline_rate, minimum_detectable_effect, alpha=0.05, power=0.80) %}
    /*
        Calculate minimum sample size needed for experiment
        
        Args:
            baseline_rate: Current metric baseline (e.g., 0.15 for 15% conversion)
            minimum_detectable_effect: Minimum effect to detect (e.g., 0.02 for 2pp lift)
            alpha: Type I error rate (default: 0.05 for 95% confidence)
            power: Statistical power (default: 0.80 for 80% power)
            
        Returns:
            Minimum sample size per variant
            
        Note: Uses simplified formula for proportion tests
    */
    CEIL(
        16 * {{ baseline_rate }} * (1 - {{ baseline_rate }}) / 
        POWER({{ minimum_detectable_effect }}, 2)
    )
{% endmacro %}

{% macro flag_outliers(value_column, threshold=3) %}
    /*
        Flag outlier values using z-score method
        
        Args:
            value_column: Column containing values to check
            threshold: Number of standard deviations (default: 3)
            
        Returns:
            Boolean indicating if value is an outlier
    */
    ABS(
        ({{ value_column }} - AVG({{ value_column }}) OVER()) / 
        NULLIF(STDDEV({{ value_column }}) OVER(), 0)
    ) > {{ threshold }}
{% endmacro %}

{% macro get_experiment_date_filter(start_date_col, end_date_col) %}
    /*
        Standard date filter for experiment analysis
        Excludes first and last day to avoid partial data
        
        Args:
            start_date_col: Column containing experiment start date
            end_date_col: Column containing experiment end date
            
        Returns:
            SQL condition for date filtering
    */
    DATE(event_timestamp) > DATE({{ start_date_col }})
    AND (
        {{ end_date_col }} IS NULL 
        OR DATE(event_timestamp) < DATE({{ end_date_col }})
    )
{% endmacro %}

{% macro calculate_statistical_power(sample_size, effect_size, alpha=0.05) %}
    /*
        Estimate statistical power of an experiment
        
        Args:
            sample_size: Actual sample size per variant
            effect_size: Observed or expected effect size
            alpha: Significance level (default: 0.05)
            
        Returns:
            Estimated statistical power (0 to 1)
            
        Note: Simplified calculation for binary metrics
    */
    -- This is a simplified approximation
    CASE
        WHEN {{ sample_size }} * POWER({{ effect_size }}, 2) > 16 THEN 0.80
        WHEN {{ sample_size }} * POWER({{ effect_size }}, 2) > 8 THEN 0.60
        WHEN {{ sample_size }} * POWER({{ effect_size }}, 2) > 4 THEN 0.40
        ELSE 0.20
    END
{% endmacro %}

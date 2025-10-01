-- Example Experiment Analysis Workflow
-- This demonstrates how to use the experimentation templates

-- 1. Run difference-in-means test for DAU metric
{{ experiment_difference_in_means('exp_001', 'fact_dau') }}

/*
-- 2. Run CUPED analysis for variance reduction
{{ experiment_cuped('exp_001', 'fact_dau', 'fact_dau_pre_experiment') }}

-- 3. Check experiment guardrails
{{ experiment_guardrails('exp_001') }}

-- 4. Analyze activation metric
{{ experiment_difference_in_means('exp_001', 'fact_activation') }}

-- 5. Analyze retention metric
{{ experiment_difference_in_means('exp_001', 'fact_retention') }}

-- 6. Analyze session duration
{{ experiment_difference_in_means('exp_001', 'fact_sessions') }}
*/

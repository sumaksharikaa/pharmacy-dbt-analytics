-- macros/calculate_fill_rate.sql
-- Reusable macro to calculate fill rate percentage

{% macro calculate_fill_rate(filled_col, total_col) %}
    round(
        cast({{ filled_col }} as numeric) * 100.0
        / nullif(cast({{ total_col }} as numeric), 0),
    2)
{% endmacro %}


-- macros/classify_cost_tier.sql
{% macro classify_cost_tier(cost_col) %}
    case
        when {{ cost_col }} >= 10000 then 'Ultra-High Cost'
        when {{ cost_col }} >= 1000  then 'High Cost'
        when {{ cost_col }} >= 100   then 'Moderate Cost'
        else 'Low Cost'
    end
{% endmacro %}


-- macros/classify_adherence.sql
{% macro classify_adherence(fills_col) %}
    case
        when {{ fills_col }} >= 4 then 'Adherent'
        when {{ fills_col }} >= 2 then 'Partially Adherent'
        else 'Non-Adherent'
    end
{% endmacro %}

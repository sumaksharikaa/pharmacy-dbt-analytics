-- tests/assert_no_negative_costs.sql
-- Singular test: no prescription should have a negative total cost

select
    rx_id,
    total_cost_usd
from {{ ref('stg_prescriptions') }}
where total_cost_usd < 0

-- tests/assert_copay_not_exceed_cost.sql
-- Singular test: member copay should never exceed total cost

select
    rx_id,
    total_cost_usd,
    member_copay_usd
from {{ ref('stg_prescriptions') }}
where member_copay_usd > total_cost_usd
  and total_cost_usd > 0

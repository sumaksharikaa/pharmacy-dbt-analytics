-- analyses/drug_spend_summary.sql
-- Ad-hoc analysis: executive drug spend summary by therapy area and tier

with utilization as (
    select * from {{ ref('mart_drug_utilization') }}
),

formulary as (
    select * from {{ ref('mart_formulary_analysis') }}
)

select
    f.therapy_area,
    f.formulary_tier,
    f.tier_label,
    f.drug_class,
    count(distinct f.drug_id)                               as drug_count,
    sum(u.total_rx)                                         as total_rx,
    sum(u.filled_rx)                                        as filled_rx,
    round(sum(u.total_cost_usd), 2)                        as total_spend_usd,
    round(sum(u.plan_paid_usd), 2)                         as plan_paid_usd,
    round(avg(u.fill_rate_pct), 2)                         as avg_fill_rate_pct,
    round(sum(f.potential_savings_generic_usd), 2)         as generic_opp_usd,

    -- spend share
    round(
        sum(u.total_cost_usd) * 100.0
        / sum(sum(u.total_cost_usd)) over (), 2
    )                                                       as pct_of_total_spend

from formulary f
left join utilization u using (drug_id)
group by 1,2,3,4
order by total_spend_usd desc nulls last

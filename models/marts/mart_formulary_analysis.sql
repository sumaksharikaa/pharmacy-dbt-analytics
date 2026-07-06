-- mart_formulary_analysis.sql
-- Mart: Formulary tier analysis — cost, utilization, and generic opportunity

with formulary as (
    select * from {{ ref('int_formulary_current') }}
),

rx as (
    select * from {{ ref('int_prescription_enriched') }}
),

formulary_utilization as (
    select
        f.drug_id,
        f.brand_name,
        f.generic_name,
        f.therapy_area,
        f.manufacturer,
        f.formulary_tier,
        f.tier_name,
        f.tier_label,
        f.drug_class,
        f.copay_pct,
        f.unit_cost_usd,
        f.est_member_cost_30d,
        f.est_plan_cost_30d,
        f.is_specialty,
        f.requires_prior_auth,
        f.cost_tier,

        -- utilization metrics
        count(rx.rx_id)                                     as total_rx,
        count(rx.rx_id) filter (where rx.is_filled)        as filled_rx,
        count(distinct rx.patient_id)                       as unique_patients,

        round(sum(rx.total_cost_usd), 2)                    as total_spend_usd,
        round(sum(rx.plan_paid_usd), 2)                     as plan_paid_usd,
        round(avg(rx.total_cost_usd), 2)                    as avg_rx_cost,

        round(
            count(rx.rx_id) filter (where rx.is_filled) * 100.0
            / nullif(count(rx.rx_id), 0), 2
        )                                                   as fill_rate_pct,

        -- generic substitution opportunity
        case
            when f.formulary_tier > 1
             and f.is_specialty = false
            then round(sum(rx.plan_paid_usd) * 0.85, 2)
            else 0
        end                                                 as potential_savings_generic_usd,

        -- tier benchmark
        round(
            sum(rx.total_cost_usd) * 100.0
            / sum(sum(rx.total_cost_usd)) over (), 2
        )                                                   as pct_of_total_spend

    from formulary f
    left join rx on f.drug_id = rx.drug_id
    group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
)

select
    *,
    -- cost efficiency score (lower cost + higher fill rate = better)
    round(fill_rate_pct / nullif(unit_cost_usd / 100.0, 0), 4)   as cost_efficiency_score
from formulary_utilization
order by total_spend_usd desc

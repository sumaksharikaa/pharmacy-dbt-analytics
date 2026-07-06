-- mart_payer_mix.sql
-- Mart: Payer mix analysis — spend, denial rate, and cost sharing by payer

with rx as (
    select * from {{ ref('int_prescription_enriched') }}
)

select
    payer_id,
    payer_name,
    payer_type,
    is_government,

    count(rx_id)                                            as total_rx,
    count(rx_id) filter (where is_filled)                  as filled_rx,
    count(distinct patient_id)                             as unique_patients,
    count(distinct drug_id)                                as unique_drugs,

    round(sum(total_cost_usd), 2)                          as total_cost_usd,
    round(sum(plan_paid_usd), 2)                           as plan_paid_usd,
    round(sum(member_copay_usd), 2)                        as member_copay_usd,

    round(avg(total_cost_usd) filter (where is_filled), 2) as avg_cost_per_rx,
    round(avg(member_copay_usd) filter (where is_filled),2)as avg_copay_per_rx,

    round(
        count(rx_id) filter (where is_filled) * 100.0
        / nullif(count(rx_id), 0), 2
    )                                                       as fill_rate_pct,

    round(
        sum(plan_paid_usd) * 100.0
        / nullif(sum(total_cost_usd), 0), 2
    )                                                       as plan_liability_pct,

    round(
        sum(total_cost_usd) * 100.0
        / sum(sum(total_cost_usd)) over (), 2
    )                                                       as pct_of_total_spend,

    count(rx_id) filter (where is_specialty)               as specialty_rx_count,
    round(sum(total_cost_usd) filter (where is_specialty), 2) as specialty_spend_usd

from rx
group by 1,2,3,4
order by total_cost_usd desc

-- mart_drug_utilization.sql
-- Mart: Drug utilization metrics — monthly spend, volume, fill rate by drug

with rx as (
    select * from {{ ref('int_prescription_enriched') }}
),

drug_monthly as (
    select
        service_month,
        service_year,
        drug_id,
        brand_name,
        generic_name,
        manufacturer,
        therapy_area,
        drug_category,
        cost_tier,
        formulary_tier,
        is_specialty,

        count(rx_id)                                        as total_rx,
        count(rx_id) filter (where is_filled = true)       as filled_rx,
        count(rx_id) filter (where is_unfilled = true)     as unfilled_rx,
        count(rx_id) filter (where is_new_rx = true)       as new_rx,
        count(distinct patient_id)                         as unique_patients,

        round(sum(total_cost_usd), 2)                      as total_cost_usd,
        round(sum(plan_paid_usd), 2)                       as plan_paid_usd,
        round(sum(member_copay_usd), 2)                    as member_copay_usd,
        round(avg(total_cost_usd), 2)                      as avg_cost_per_rx,
        round(avg(days_supply), 1)                         as avg_days_supply,

        round(
            count(rx_id) filter (where is_filled = true) * 100.0
            / nullif(count(rx_id), 0), 2
        )                                                   as fill_rate_pct,

        round(
            sum(plan_paid_usd) * 100.0
            / nullif(sum(total_cost_usd), 0), 2
        )                                                   as plan_liability_pct

    from rx
    group by 1,2,3,4,5,6,7,8,9,10,11
),

with_mom as (
    select
        *,
        lag(total_cost_usd) over (
            partition by drug_id
            order by service_month
        )                                                   as prior_month_cost,

        round(
            (total_cost_usd - lag(total_cost_usd) over (
                partition by drug_id order by service_month
            )) / nullif(lag(total_cost_usd) over (
                partition by drug_id order by service_month
            ), 0) * 100, 2
        )                                                   as cost_mom_pct_change,

        sum(total_cost_usd) over (
            partition by drug_id
            order by service_month
            rows between unbounded preceding and current row
        )                                                   as cumulative_spend_usd

    from drug_monthly
)

select * from with_mom
order by service_month, total_cost_usd desc

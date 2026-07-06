-- mart_patient_adherence.sql
-- Mart: Patient-level adherence and utilization metrics

with rx as (
    select * from {{ ref('int_prescription_enriched') }}
),

patient_summary as (
    select
        patient_id,
        age,
        age_band,
        gender,
        state,
        insurance_type,
        payer_name,
        is_medicare,

        count(rx_id)                                        as total_rx,
        count(rx_id) filter (where is_filled)              as filled_rx,
        count(rx_id) filter (where is_new_rx)              as new_rx,
        count(distinct drug_id)                            as unique_drugs,
        count(distinct therapy_area)                       as therapy_areas_count,

        round(sum(total_cost_usd), 2)                      as total_spend_usd,
        round(sum(plan_paid_usd), 2)                       as plan_paid_usd,
        round(sum(member_copay_usd), 2)                    as out_of_pocket_usd,
        round(avg(total_cost_usd) filter (where is_filled),2) as avg_rx_cost,
        max(refill_number)                                 as max_refill_number,

        round(
            count(rx_id) filter (where is_filled) * 100.0
            / nullif(count(rx_id), 0), 2
        )                                                   as fill_rate_pct,

        -- adherence classification (PDC proxy)
        case
            when count(rx_id) filter (where is_filled) >= 4
            then 'Adherent'
            when count(rx_id) filter (where is_filled) >= 2
            then 'Partially Adherent'
            else 'Non-Adherent'
        end                                                 as adherence_status,

        -- high utilizer flag (top spending patients)
        case
            when sum(total_cost_usd) > 10000 then true
            else false
        end                                                 as is_high_utilizer,

        bool_or(is_specialty)                              as has_specialty_rx,

        min(service_date)                                  as first_rx_date,
        max(service_date)                                  as last_rx_date

    from rx
    group by 1,2,3,4,5,6,7,8
)

select
    *,
    -- spend decile using window function
    ntile(10) over (order by total_spend_usd desc)          as spend_decile,
    -- days since last fill
    current_date - last_rx_date                             as days_since_last_fill
from patient_summary
order by total_spend_usd desc

-- stg_prescriptions.sql
with source as (select * from {{ ref('raw_prescriptions') }}),
cleaned as (
    select
        rx_id,
        patient_id,
        drug_id,
        payer_id,
        cast(service_date as date)                      as service_date,
        cast(days_supply as integer)                    as days_supply,
        cast(quantity_dispensed as integer)             as quantity_dispensed,
        cast(formulary_tier as integer)                 as formulary_tier,
        cast(total_cost_usd as numeric(10,2))           as total_cost_usd,
        cast(member_copay_usd as numeric(10,2))         as member_copay_usd,
        cast(plan_paid_usd as numeric(10,2))            as plan_paid_usd,
        cast(is_filled as boolean)                      as is_filled,
        cast(is_specialty as boolean)                   as is_specialty,
        trim(therapy_area)                              as therapy_area,
        cast(refill_number as integer)                  as refill_number,
        trim(pharmacy_type)                             as pharmacy_type,

        -- derived date parts
        date_trunc('month', cast(service_date as date)) as service_month,
        date_trunc('quarter',cast(service_date as date))as service_quarter,
        extract(year from cast(service_date as date))   as service_year,

        -- derived flags
        case when refill_number = 0 then true else false end as is_new_rx,
        case when is_filled = false then true else false end as is_unfilled,

        -- plan share
        case
            when total_cost_usd > 0
            then round(plan_paid_usd / total_cost_usd * 100, 2)
            else 0
        end                                             as plan_liability_pct,

        current_timestamp                               as _loaded_at

    from source
    where rx_id is not null
      and patient_id is not null
      and drug_id is not null
      and total_cost_usd >= 0
)
select * from cleaned

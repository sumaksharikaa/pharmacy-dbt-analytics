-- stg_formulary.sql
-- Staging model: clean formulary tier data with current flag logic

with source as (
    select * from {{ ref('raw_formulary') }}
),

cleaned as (
    select
        formulary_id,
        drug_id,
        cast(formulary_tier as integer)                 as formulary_tier,
        trim(tier_name)                                 as tier_name,
        cast(copay_pct as numeric(5,2))                 as copay_pct,
        cast(effective_date as date)                    as effective_date,
        cast(end_date as date)                          as end_date,
        cast(plan_year as integer)                      as plan_year,
        trim(change_reason)                             as change_reason,
        cast(is_current as boolean)                     as is_current,

        -- derived
        case formulary_tier
            when 1 then 'Tier 1 — Preferred Generic'
            when 2 then 'Tier 2 — Non-Preferred Generic'
            when 3 then 'Tier 3 — Preferred Brand'
            when 4 then 'Tier 4 — Non-Preferred Brand'
            when 5 then 'Tier 5 — Specialty'
            else 'Unknown'
        end                                             as tier_label,

        case
            when formulary_tier <= 2 then 'Generic'
            when formulary_tier <= 4 then 'Brand'
            else 'Specialty'
        end                                             as drug_class,

        current_timestamp                               as _loaded_at

    from source
    where formulary_id is not null
      and drug_id is not null
      and formulary_tier between 1 and 5
)

select * from cleaned

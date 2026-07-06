-- stg_drugs.sql
-- Staging model: clean and standardize raw drug master data

with source as (
    select * from {{ ref('raw_drugs') }}
),

renamed as (
    select
        drug_id,
        upper(trim(brand_name))                         as brand_name,
        upper(trim(generic_name))                       as generic_name,
        trim(manufacturer)                              as manufacturer,
        trim(therapy_area)                              as therapy_area,
        trim(dosage_form)                               as dosage_form,
        trim(strength)                                  as strength,
        ndc,
        cast(unit_cost_usd as numeric(10,2))            as unit_cost_usd,
        cast(requires_prior_auth as boolean)            as requires_prior_auth,
        cast(is_specialty as boolean)                   as is_specialty,
        cast(is_active as boolean)                      as is_active,

        -- derived fields
        case
            when is_specialty = true then 'Specialty'
            else 'Non-Specialty'
        end                                             as drug_category,

        case
            when unit_cost_usd >= 10000 then 'Ultra-High Cost'
            when unit_cost_usd >= 1000  then 'High Cost'
            when unit_cost_usd >= 100   then 'Moderate Cost'
            else 'Low Cost'
        end                                             as cost_tier,

        current_timestamp                               as _loaded_at

    from source
    where drug_id is not null
      and brand_name is not null
      and unit_cost_usd > 0
)

select * from renamed

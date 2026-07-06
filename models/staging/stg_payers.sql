-- stg_payers.sql
with source as (select * from {{ ref('raw_payers') }}),
cleaned as (
    select
        payer_id,
        trim(payer_name)                                as payer_name,
        trim(payer_type)                                as payer_type,
        cast(is_active as boolean)                      as is_active,
        case payer_type
            when 'Government' then true else false
        end                                             as is_government,
        current_timestamp                               as _loaded_at
    from source
    where payer_id is not null
)
select * from cleaned

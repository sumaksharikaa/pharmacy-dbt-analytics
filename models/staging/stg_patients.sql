-- stg_patients.sql
with source as (select * from {{ ref('raw_patients') }}),
cleaned as (
    select
        patient_id,
        cast(age as integer)                            as age,
        upper(trim(gender))                             as gender,
        upper(trim(state))                              as state,
        trim(insurance_type)                            as insurance_type,
        payer_id,
        cast(enrollment_date as date)                   as enrollment_date,
        cast(is_active as boolean)                      as is_active,

        -- derived
        case
            when age < 30  then '18-29'
            when age < 45  then '30-44'
            when age < 60  then '45-59'
            when age < 75  then '60-74'
            else '75+'
        end                                             as age_band,

        case
            when insurance_type = 'Medicare' then true
            else false
        end                                             as is_medicare,

        current_timestamp                               as _loaded_at

    from source
    where patient_id is not null
      and age between 0 and 120
)
select * from cleaned

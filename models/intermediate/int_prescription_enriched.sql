-- int_prescription_enriched.sql
-- Intermediate model: join prescriptions with drug, payer, and patient data

with prescriptions as (
    select * from {{ ref('stg_prescriptions') }}
),

drugs as (
    select * from {{ ref('stg_drugs') }}
),

patients as (
    select * from {{ ref('stg_patients') }}
),

payers as (
    select * from {{ ref('stg_payers') }}
),

enriched as (
    select
        -- prescription fields
        rx.rx_id,
        rx.service_date,
        rx.service_month,
        rx.service_quarter,
        rx.service_year,
        rx.days_supply,
        rx.quantity_dispensed,
        rx.formulary_tier,
        rx.total_cost_usd,
        rx.member_copay_usd,
        rx.plan_paid_usd,
        rx.plan_liability_pct,
        rx.is_filled,
        rx.is_specialty,
        rx.is_new_rx,
        rx.is_unfilled,
        rx.refill_number,
        rx.pharmacy_type,
        rx.therapy_area,

        -- drug fields
        d.drug_id,
        d.brand_name,
        d.generic_name,
        d.manufacturer,
        d.drug_category,
        d.cost_tier,
        d.unit_cost_usd,
        d.requires_prior_auth,

        -- patient fields
        p.patient_id,
        p.age,
        p.age_band,
        p.gender,
        p.state,
        p.insurance_type,
        p.is_medicare,

        -- payer fields
        py.payer_id,
        py.payer_name,
        py.payer_type,
        py.is_government

    from prescriptions rx
    left join drugs d    on rx.drug_id    = d.drug_id
    left join patients p on rx.patient_id = p.patient_id
    left join payers py  on rx.payer_id   = py.payer_id
)

select * from enriched

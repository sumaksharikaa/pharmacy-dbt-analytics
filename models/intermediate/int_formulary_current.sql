-- int_formulary_current.sql
-- Intermediate model: latest formulary tier per drug (current snapshot)

with formulary as (
    select * from {{ ref('stg_formulary') }}
),

drugs as (
    select * from {{ ref('stg_drugs') }}
),

ranked as (
    select
        f.*,
        row_number() over (
            partition by f.drug_id
            order by f.plan_year desc, f.effective_date desc
        ) as rn
    from formulary f
),

current_formulary as (
    select
        r.formulary_id,
        r.drug_id,
        r.formulary_tier,
        r.tier_name,
        r.tier_label,
        r.drug_class,
        r.copay_pct,
        r.effective_date,
        r.plan_year,
        r.change_reason,

        -- drug attributes
        d.brand_name,
        d.generic_name,
        d.therapy_area,
        d.manufacturer,
        d.unit_cost_usd,
        d.is_specialty,
        d.requires_prior_auth,
        d.cost_tier,

        -- estimated member cost per 30-day fill
        round(d.unit_cost_usd * r.copay_pct, 2)     as est_member_cost_30d,

        -- estimated plan cost per 30-day fill
        round(d.unit_cost_usd * (1 - r.copay_pct), 2) as est_plan_cost_30d

    from ranked r
    join drugs d on r.drug_id = d.drug_id
    where r.rn = 1
)

select * from current_formulary

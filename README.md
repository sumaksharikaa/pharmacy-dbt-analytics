# 💊 Pharmacy Analytics dbt Project

[![dbt](https://img.shields.io/badge/dbt-1.7-orange?logo=dbt)](https://www.getdbt.com)
[![Snowflake](https://img.shields.io/badge/Snowflake-blue?logo=snowflake)](https://www.snowflake.com)
[![SQL](https://img.shields.io/badge/SQL-Advanced-blue)](https://sql.org)

End-to-end analytics engineering project using **dbt + SQL** to build modular, tested, and documented data models for pharmacy drug sales and formulary analytics on Snowflake. Demonstrates production-grade dbt patterns including staging → intermediate → mart layering, schema tests, singular tests, macros, and documentation.

---

## 🗂️ Project Structure

```
pharmacy-dbt-analytics/
├── dbt_project.yml                  # Project config and materializations
├── profiles.yml                     # Snowflake connection profiles (dev/prod)
├── seeds/
│   ├── raw_drugs.csv                # Drug master (15 drugs)
│   ├── raw_formulary.csv            # Formulary tier history (19 records)
│   ├── raw_payers.csv               # Payer master (7 payers)
│   ├── raw_patients.csv             # Patient cohort (500 patients)
│   └── raw_prescriptions.csv        # Prescription claims (4,000 Rx)
├── models/
│   ├── staging/                     # Source cleaning + standardization
│   │   ├── stg_drugs.sql
│   │   ├── stg_formulary.sql
│   │   ├── stg_payers.sql
│   │   ├── stg_patients.sql
│   │   ├── stg_prescriptions.sql
│   │   └── schema.yml               # Column tests + documentation
│   ├── intermediate/                # Business logic joins
│   │   ├── int_prescription_enriched.sql
│   │   ├── int_formulary_current.sql
│   │   └── schema.yml
│   └── marts/                       # Analytics-ready tables
│       ├── mart_drug_utilization.sql
│       ├── mart_formulary_analysis.sql
│       ├── mart_payer_mix.sql
│       ├── mart_patient_adherence.sql
│       └── schema.yml
├── tests/
│   ├── assert_no_negative_costs.sql
│   └── assert_copay_not_exceed_cost.sql
├── macros/
│   └── pharmacy_macros.sql
└── analyses/
    └── drug_spend_summary.sql
```

---

## 🏗️ Data Model Architecture

```
seeds (raw CSVs)
    │
    ▼
staging (views)          ← cleaning, casting, derived fields
    │
    ▼
intermediate (views)     ← joins, business logic
    │
    ▼
marts (tables)           ← analytics-ready, indexed, documented
```

---

## 📊 Mart Models

| Mart | Grain | Key Metrics |
|---|---|---|
| `mart_drug_utilization` | Drug × Month | Spend, fill rate, MoM change, cumulative spend |
| `mart_formulary_analysis` | Drug | Tier, copay %, generic savings opportunity |
| `mart_payer_mix` | Payer | Spend share, plan liability %, specialty Rx |
| `mart_patient_adherence` | Patient | Adherence status, spend decile, high utilizer flag |

---

## 🧪 Testing Strategy

| Test Type | Count | Examples |
|---|---|---|
| `not_null` | 20+ | All PK and FK columns |
| `unique` | 8 | All primary keys |
| `accepted_values` | 10+ | therapy_area, formulary_tier, gender, insurance_type |
| `relationships` | 4 | FK integrity across all models |
| Singular tests | 2 | No negative costs, copay ≤ total cost |

---

## 🔧 Macros

| Macro | Purpose |
|---|---|
| `calculate_fill_rate(filled, total)` | Reusable fill rate % calculation |
| `classify_cost_tier(cost)` | Ultra-High / High / Moderate / Low cost classification |
| `classify_adherence(fills)` | Adherent / Partially Adherent / Non-Adherent |

---

## ⚙️ Setup & Run

### 1. Prerequisites
```bash
pip install dbt-snowflake
```

### 2. Configure Snowflake connection
```bash
# Set environment variables
export SNOWFLAKE_ACCOUNT=your_account
export SNOWFLAKE_USER=your_user
export SNOWFLAKE_PASSWORD=your_password
```

### 3. Run the project
```bash
# Load seed data
dbt seed

# Run all models
dbt run

# Run tests
dbt test

# Generate documentation
dbt docs generate
dbt docs serve

# Run everything in order
dbt build
```

### 4. Run specific layers
```bash
dbt run --select staging
dbt run --select intermediate
dbt run --select marts
dbt run --select mart_drug_utilization
```

---

## 🔑 Key dbt Concepts Demonstrated

| Concept | Implementation |
|---|---|
| **Layered architecture** | staging → intermediate → marts |
| **Materializations** | Views (staging, intermediate), Tables (marts) |
| **Schema tests** | not_null, unique, accepted_values, relationships |
| **Singular tests** | Custom SQL tests for business rules |
| **Macros** | Reusable Jinja SQL functions |
| **Seeds** | CSV source data loaded via `dbt seed` |
| **Documentation** | Full column-level docs in schema.yml |
| **Analyses** | Ad-hoc SQL for executive reporting |
| **Window functions** | MoM change, cumulative spend, NTILE deciles |
| **Multi-env profiles** | Dev and prod Snowflake targets |

---

## 🔗 Related Projects

- [Specialty Pharmacy Claims Analytics](https://github.com/sumaksharikaa/sp-claims-analytics)
- [Drug Utilization & Formulary Analytics](https://github.com/sumaksharikaa/drug-utilization-analytics)
- [Pharmacy Supply Chain Analytics](https://github.com/sumaksharikaa/pharmacy-supply-chain)

---

*Built by [Sumaksharika Nainavarapu](https://github.com/sumaksharikaa)*

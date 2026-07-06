"""
generate_seeds.py
Generates CSV seed files for the pharmacy dbt analytics project.
"""

import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta
import os

random.seed(42)
np.random.seed(42)

OUT = os.path.join(os.path.dirname(__file__), "..", "seeds")

def rdate(s=datetime(2022,1,1), e=datetime(2024,12,31)):
    return (s + timedelta(days=random.randint(0,(e-s).days))).strftime("%Y-%m-%d")

# ── raw_drugs ─────────────────────────────────────────────────────────────────
drugs = pd.DataFrame([
    ("DRG001","Humira","Adalimumab","AbbVie","Immunology","Injection","40mg",6500,True,True),
    ("DRG002","Enbrel","Etanercept","Pfizer","Immunology","Injection","50mg",5800,True,True),
    ("DRG003","Stelara","Ustekinumab","Janssen","Dermatology","Injection","45mg",18000,True,True),
    ("DRG004","Ozempic","Semaglutide","Novo Nordisk","Diabetes","Injection","1mg",850,True,False),
    ("DRG005","Keytruda","Pembrolizumab","Merck","Oncology","Injection","200mg",22000,True,True),
    ("DRG006","Lipitor","Atorvastatin","Pfizer","Cardiology","Tablet","20mg",12,False,False),
    ("DRG007","Metformin","Metformin HCl","Generic","Diabetes","Tablet","500mg",4,False,False),
    ("DRG008","Eliquis","Apixaban","BMS/Pfizer","Cardiology","Tablet","5mg",145,False,False),
    ("DRG009","Dupixent","Dupilumab","Sanofi","Dermatology","Injection","300mg",3200,True,True),
    ("DRG010","Lisinopril","Lisinopril","Generic","Cardiology","Tablet","10mg",3,False,False),
    ("DRG011","Tecfidera","Dimethyl Fumarate","Biogen","Neurology","Capsule","240mg",8100,True,False),
    ("DRG012","Januvia","Sitagliptin","Merck","Diabetes","Tablet","100mg",85,False,False),
    ("DRG013","Xarelto","Rivaroxaban","J&J","Cardiology","Tablet","20mg",140,False,False),
    ("DRG014","Revlimid","Lenalidomide","BMS","Oncology","Capsule","25mg",19000,True,True),
    ("DRG015","Omeprazole","Omeprazole","Generic","Gastroenterology","Capsule","20mg",6,False,False),
], columns=["drug_id","brand_name","generic_name","manufacturer","therapy_area",
            "dosage_form","strength","unit_cost_usd","requires_prior_auth","is_specialty"])
drugs["ndc"] = [f"{random.randint(10000,99999)}-{random.randint(100,999)}-{random.randint(10,99)}"
                for _ in range(len(drugs))]
drugs["is_active"] = True
drugs.to_csv(f"{OUT}/raw_drugs.csv", index=False)

# ── raw_formulary ─────────────────────────────────────────────────────────────
TIER_MAP = {1:("Preferred Generic",0.10), 2:("Non-Preferred Generic",0.20),
            3:("Preferred Brand",0.30), 4:("Non-Preferred Brand",0.45), 5:("Specialty",0.60)}
TIER_ASSIGN = {"DRG001":4,"DRG002":4,"DRG003":5,"DRG004":3,"DRG005":5,
               "DRG006":2,"DRG007":1,"DRG008":2,"DRG009":4,"DRG010":1,
               "DRG011":4,"DRG012":3,"DRG013":2,"DRG014":5,"DRG015":1}
form_rows = []
for drug_id, tier in TIER_ASSIGN.items():
    tier_name, copay = TIER_MAP[tier]
    form_rows.append({"formulary_id":f"FORM{len(form_rows)+1:04d}","drug_id":drug_id,
        "formulary_tier":tier,"tier_name":tier_name,"copay_pct":copay,
        "effective_date":"2022-01-01","end_date":None,"plan_year":2022,
        "change_reason":"Initial placement","is_current":True})
    if random.random() < 0.25:
        new_tier = max(1,min(5,tier+random.choice([-1,1])))
        tn, cp = TIER_MAP[new_tier]
        form_rows.append({"formulary_id":f"FORM{len(form_rows)+1:04d}","drug_id":drug_id,
            "formulary_tier":new_tier,"tier_name":tn,"copay_pct":cp,
            "effective_date":"2023-01-01","end_date":None,"plan_year":2023,
            "change_reason":random.choice(["Annual review","Generic available","Contract update"]),
            "is_current":True})

pd.DataFrame(form_rows).to_csv(f"{OUT}/raw_formulary.csv", index=False)

# ── raw_payers ────────────────────────────────────────────────────────────────
payers = pd.DataFrame([
    ("PAY001","BlueCross BlueShield","Commercial"),
    ("PAY002","Aetna","Commercial"),
    ("PAY003","Cigna","Commercial"),
    ("PAY004","UnitedHealthcare","Commercial"),
    ("PAY005","Medicare Part D","Government"),
    ("PAY006","Medicaid","Government"),
    ("PAY007","Humana","Commercial"),
], columns=["payer_id","payer_name","payer_type"])
payers["is_active"] = True
payers.to_csv(f"{OUT}/raw_payers.csv", index=False)

# ── raw_patients ──────────────────────────────────────────────────────────────
n = 500
patients = pd.DataFrame({
    "patient_id":     [f"PT{i:06d}" for i in range(1,n+1)],
    "age":            np.random.randint(18,85,n),
    "gender":         np.random.choice(["M","F","Other"],n,p=[0.48,0.49,0.03]),
    "state":          np.random.choice(["NC","TX","CA","FL","NY","GA","OH","PA"],n),
    "insurance_type": np.random.choice(["Commercial","Medicare","Medicaid"],n,p=[0.55,0.30,0.15]),
    "payer_id":       np.random.choice(payers["payer_id"].tolist(),n),
    "enrollment_date":[rdate(datetime(2022,1,1),datetime(2022,6,30)) for _ in range(n)],
    "is_active":      True,
})
patients.to_csv(f"{OUT}/raw_patients.csv", index=False)

# ── raw_prescriptions ─────────────────────────────────────────────────────────
drug_ids  = drugs["drug_id"].tolist()
pat_ids   = patients["patient_id"].tolist()
rx_rows   = []
for i in range(1, 4001):
    drug   = drugs.sample(1).iloc[0]
    tier   = TIER_ASSIGN.get(drug["drug_id"], 3)
    copay  = TIER_MAP[tier][1]
    qty    = random.randint(1,3)
    cost   = round(drug["unit_cost_usd"] * qty * random.uniform(0.95,1.05), 2)
    filled = random.random() > 0.08
    svc_d  = rdate()
    rx_rows.append({
        "rx_id":            f"RX{i:07d}",
        "patient_id":       random.choice(pat_ids),
        "drug_id":          drug["drug_id"],
        "payer_id":         random.choice(payers["payer_id"].tolist()),
        "service_date":     svc_d,
        "days_supply":      random.choice([30,60,90]),
        "quantity_dispensed":qty if filled else 0,
        "formulary_tier":  tier,
        "total_cost_usd":  cost,
        "member_copay_usd":round(cost*copay,2) if filled else 0,
        "plan_paid_usd":   round(cost*(1-copay),2) if filled else 0,
        "is_filled":       filled,
        "is_specialty":    drug["is_specialty"],
        "therapy_area":    drug["therapy_area"],
        "refill_number":   random.randint(0,5),
        "pharmacy_type":   random.choice(["Retail","Mail Order","Specialty"]),
    })

pd.DataFrame(rx_rows).to_csv(f"{OUT}/raw_prescriptions.csv", index=False)

print("✅ Seeds generated:")
for f in ["raw_drugs","raw_formulary","raw_payers","raw_patients","raw_prescriptions"]:
    df = pd.read_csv(f"{OUT}/{f}.csv")
    print(f"   {f+'.csv':<30} → {len(df):,} rows")

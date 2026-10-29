# Tableau Dashboard — Build Guide

Data source: `tableau/churn_dashboard_data.csv` (created by `sql/05_tableau_export.sql`, one row per customer, 23 columns).
Works in Tableau Public (free) or Tableau Desktop.

---

## 1. Connect

1. Open Tableau → **Connect → Text file** → choose `churn_dashboard_data.csv`.
2. On the Data Source page check the types:
   - `churn_flag`, `tenure`, `addon_count`, `risk_score` → Number (whole)
   - `monthly_charges`, `total_charges`, `annual_revenue` → Number (decimal)
   - Everything else → String
3. Rename the data source to **Churn**.

---

## 2. Calculated fields

Create these via **Analysis → Create Calculated Field**. Copy each formula exactly.

**Churn Rate**
```
SUM([churn_flag]) / COUNT([customer_id])
```
Format: Percentage, 1 decimal.

**Customers**
```
COUNTD([customer_id])
```

**Churned Customers**
```
SUM([churn_flag])
```

**Monthly Revenue Lost**
```
SUM(IF [churn_flag] = 1 THEN [monthly_charges] END)
```

**Revenue Lost %**
```
[Monthly Revenue Lost] / SUM([monthly_charges])
```

**Revenue at Risk (12 mo)** — active customers in the High tier
```
SUM(IF [risk_tier] = "High" AND [churn_flag] = 0 THEN [monthly_charges] * 12 END)
```

**Churn Rate vs Average** — for colour coding bars above/below the company average
```
[Churn Rate] - WINDOW_AVG([Churn Rate])
```
(Better version using a fixed overall rate:)
```
[Churn Rate] - { FIXED : SUM([churn_flag]) / COUNT([customer_id]) }
```

**Tenure Band Order** — keeps bands in lifecycle order
```
CASE [tenure_band]
  WHEN "0-12 months"  THEN 1
  WHEN "13-24 months" THEN 2
  WHEN "25-48 months" THEN 3
  ELSE 4
END
```

**Risk Tier Order**
```
CASE [risk_tier] WHEN "High" THEN 1 WHEN "Medium" THEN 2 ELSE 3 END
```

### Parameters (for the what-if campaign tile)
| Parameter | Type | Current value | Range |
|---|---|---|---|
| p_SaveRate | Float, % | 0.25 | 0.05 – 0.50, step 0.05 |
| p_Discount | Float, % | 0.20 | 0.05 – 0.40, step 0.05 |
| p_Acceptance | Float, % | 0.40 | 0.10 – 0.80, step 0.10 |

**Campaign Net Benefit**
```
SUM(IF [risk_tier] = "High" AND [churn_flag] = 1
    THEN [monthly_charges] * [p_SaveRate] * (1 - [p_Discount]) * 12 END)
-
SUM(IF [risk_tier] = "High" AND [churn_flag] = 0
    THEN [monthly_charges] * [p_Acceptance] * [p_Discount] * 12 END)
```
With the default parameters this should show **≈ $169,534**, matching the SQL and Excel results.

Right-click each parameter → **Show Parameter** so viewers can move the sliders.

---

## 3. Worksheets

| # | Sheet name | Columns | Rows | Marks / colour | Notes |
|---|---|---|---|---|---|
| 1 | KPI – Churn Rate | – | – | Text: `Churn Rate` | Large font, label "Churn rate" |
| 2 | KPI – Customers | – | – | Text: `Customers`, `Churned Customers` | |
| 3 | KPI – Revenue Lost | – | – | Text: `Monthly Revenue Lost`, `Revenue Lost %` | Currency format |
| 4 | Churn by Contract | `Churn Rate` | `contract` | Bar; Colour: `Churn Rate vs Average` (diverging red–grey) | Sort descending; label marks |
| 5 | Churn by Tenure | `tenure_band` (sort by `Tenure Band Order`) | `Churn Rate` | Line + circle marks | Shows churn falling with tenure |
| 6 | Churn by Payment | `Churn Rate` | `payment_method` | Bar | Sort descending |
| 7 | Contract × Tenure Heatmap | `tenure_band` | `contract` | Square; Colour: `Churn Rate` (red sequential); Label: `Churn Rate` | Main "insight" chart |
| 8 | Add-on Services | `addon_count` (discrete) | `Churn Rate` | Bar; Size or label: `Customers` | |
| 9 | Risk Tier Validation | `risk_tier` (sort by `Risk Tier Order`) | `Churn Rate` | Bar; Label: `Customers` | Shows the score separates churners |
| 10 | Campaign What-If | – | – | Text: `Campaign Net Benefit`, `Revenue at Risk (12 mo)` | Show the three parameter sliders |

Tips:
- Format `Churn Rate` axes as `0%`.
- Use one red for "churn" everywhere and grey for everything else — consistent colour reads as professional.
- Add a tooltip to every bar: `<contract>: <Churn Rate> churn across <Customers> customers`.

---

## 4. Dashboard layout (1200 × 800, fixed size)

```
┌──────────────────────────────────────────────────────────────────┐
│  Telco Customer Churn — What drives it and what it costs          │
├──────────────┬──────────────┬──────────────┬─────────────────────┤
│ Churn rate   │ Customers /  │ Revenue lost │ Filters:            │
│  26.5%       │ Churned      │ $139K / mo   │ internet_service,   │
│              │              │ (30.5%)      │ senior_citizen      │
├──────────────┴──────────────┼──────────────┴─────────────────────┤
│ Contract × Tenure heatmap   │ Churn by contract                  │
│                             ├────────────────────────────────────┤
│                             │ Churn by payment method            │
├──────────────┬──────────────┴──────┬─────────────────────────────┤
│ Churn by     │ Risk tier           │ Campaign what-if             │
│ tenure       │ validation          │ (sliders + net benefit)      │
└──────────────┴─────────────────────┴─────────────────────────────┘
```

Interactivity:
1. **Dashboard → Actions → Add Action → Filter**: source = *Churn by Contract*, target = all sheets, run on *Select*. Clicking "Month-to-month" filters the whole dashboard.
2. Add `internet_service` and `senior_citizen` as filters, **Apply to Worksheets → All using this data source**.
3. Add a text box with 3 key findings (from the README) under the title.

---

## 5. Publish

1. **File → Save to Tableau Public**.
2. Copy the public link into your README and resume.
3. Take a screenshot → save as `images/dashboard.png` for the GitHub README.

### Expected values (to check your build)
| Metric | Value |
|---|---|
| Overall churn rate | 26.5% |
| Month-to-month churn | 42.7% |
| Two-year contract churn | 2.8% |
| Electronic check churn | 45.3% |
| Month-to-month + 0-12 months heatmap cell | 51.4% |
| High risk tier churn rate | 57.3% |
| Campaign net benefit (default sliders) | ≈ $169.5K |

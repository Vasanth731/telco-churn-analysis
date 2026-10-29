# Telco Customer Churn Analysis — SQL · Excel · Tableau

End-to-end analysis of why customers leave a telecom provider, which customers are most at risk, and how much revenue a targeted retention campaign could save.

**Tools:** SQL (PostgreSQL / DuckDB) for cleaning and analysis · Excel for driver analysis and an ROI model · Tableau for the interactive dashboard
**Dataset:** [IBM Telco Customer Churn](https://github.com/IBM/telco-customer-churn-on-icp4d) — 7,043 customers, 21 attributes

<!-- ![Dashboard](images/dashboard.png) -->
<!-- [View the interactive dashboard on Tableau Public](your-link-here) -->

---

## Business questions
1. How big is the churn problem, in customers and revenue?
2. Which customer and service characteristics drive churn?
3. Can we identify high-risk customers before they leave?
4. Is a retention offer worth the cost?

---

## Key findings

| | |
|---|---|
| **26.5%** of customers churned | They took **30.5%** of monthly revenue ($139K/month) with them |
| **Contract type is the #1 driver** | Month-to-month churn is **42.7%** vs **2.8%** on two-year contracts |
| **The first year is critical** | Churn is **47.4%** in months 0–12, falling to **9.5%** after 4 years |
| **New month-to-month customers** | 51.4% churn, and this single segment produces **55%** of all churners |
| **Payment method matters** | Electronic-check customers churn at **45.3%**, ~3× automatic-payment customers |
| **Support add-ons protect** | No tech support: 41.6% churn vs 15.2% with it (same pattern for online security) |
| **Fiber optic customers churn more** | 41.9% vs 19.0% on DSL despite being the highest-value plan — a likely price/quality issue |

### Risk score
A transparent, rule-based risk score (0–100) built from the drivers above:

| Risk tier | Customers | Churn rate | Share of all churners |
|---|---|---|---|
| High | 2,229 | **57.3%** | 68.4% |
| Medium | 2,029 | 22.9% | 24.9% |
| Low | 2,785 | 4.5% | 6.7% |

Treating "High" as a churn prediction gives **68% recall** and **57% precision** — a **2.2× lift** over random targeting. The top 30% of customers by score contain 66% of all churners.

### Retention campaign
Offering High-risk customers a 20% discount to move to a 1-year contract, assuming 25% of would-be churners are saved and 40% of stayers also take the discount:

- Revenue at risk over 12 months: **$1.19M**
- Revenue saved (after discount): **$237K**
- Cost of discounts to customers who would have stayed: **$68K**
- **Net benefit: ≈ $170K per year — $3.50 retained per $1 of discount**

The Excel sensitivity table shows the campaign stays profitable down to a ~10% save rate at discounts up to 25%.

---

## Recommendations
1. **Convert month-to-month customers to annual contracts** in their first 12 months, using a targeted discount.
2. **Push auto-pay**: incentivise electronic-check customers to switch to bank transfer or card.
3. **Bundle tech support and online security** into fiber plans for new customers.
4. **Investigate fiber optic service quality and pricing** — high value customers are leaving at twice the DSL rate.
5. **Score customers monthly** and route the High tier to the retention team.

---

## Project structure

```
.
├── data/
│   └── Telco-Customer-Churn.csv
├── sql/
│   ├── 01_create_and_load.sql          # schema, load, data-quality checks
│   ├── 02_clean_transform.sql          # type fixes, missing values, feature engineering
│   ├── 03_churn_drivers.sql            # 10 business questions (GROUP BY, UNION, window functions)
│   ├── 04_risk_score_and_campaign.sql  # risk score, confusion matrix, deciles, campaign ROI
│   └── 05_tableau_export.sql           # dashboard view + CSV export
├── excel/
│   └── Churn_Analysis.xlsx             # formula-driven drivers analysis, charts, ROI + sensitivity model
├── tableau/
│   ├── TABLEAU_GUIDE.md                # calculated fields, sheets, dashboard layout
│   └── churn_dashboard_data.csv        # exported from SQL
└── README.md
```

---

## How to run

### SQL
**DuckDB** (no server needed; install the CLI from [duckdb.org](https://duckdb.org/docs/installation)):
```bash
duckdb churn.duckdb < sql/01_create_and_load.sql
duckdb churn.duckdb < sql/02_clean_transform.sql
duckdb churn.duckdb < sql/03_churn_drivers.sql
duckdb churn.duckdb < sql/04_risk_score_and_campaign.sql
duckdb churn.duckdb < sql/05_tableau_export.sql
```
Run from the project root so the relative file paths resolve.

**PostgreSQL:** in `01_create_and_load.sql` and `05_tableau_export.sql`, comment out the DuckDB `COPY` lines and uncomment the `\copy` lines, then run the scripts in order with `psql -f`.

### Excel
Open `excel/Churn_Analysis.xlsx`. All analysis cells are live formulas on the `Data` sheet (COUNTIFS, SUMIFS, nested IF feature columns). Change the yellow inputs on **Retention Campaign** to test scenarios.

### Tableau
Follow `tableau/TABLEAU_GUIDE.md`.

---

## Skills demonstrated
- **SQL:** data loading and validation, cleaning and type casting, CASE-based feature engineering, aggregation, UNION, window functions (`SUM() OVER`, `NTILE`), CTEs, views
- **Excel:** COUNTIFS / SUMIFS analysis, formula-based feature columns, conditional formatting, charts, assumption-driven financial model, sensitivity table
- **Tableau:** calculated fields, LOD expressions, parameters for what-if analysis, dashboard actions and filters
- **Analytics:** churn driver analysis, segmentation, model evaluation (precision, recall, lift, gains), translating findings into a revenue impact and business recommendations

---

## Limitations and next steps
- The risk score is rule-based for transparency; a logistic regression or gradient-boosted model in Python would likely improve precision.
- The dataset is a single snapshot, so churn timing and true cohort retention can't be measured.
- Campaign assumptions (save rate, acceptance) should be validated with an A/B test before rollout.

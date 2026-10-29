-- =====================================================================
-- 04_risk_score_and_campaign.sql
-- 1) A transparent, rule-based churn risk score built from the drivers
--    found in 03_churn_drivers.sql
-- 2) How well the score separates churners (precision / recall / lift)
-- 3) Revenue a targeted retention campaign could save
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Risk score (0-100). Weights are set from the size of each driver's
--    effect in the exploratory analysis.
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS churn_scored;

CREATE TABLE churn_scored AS
WITH points AS (
    SELECT
        c.*,
          (CASE contract WHEN 'Month-to-month' THEN 30 WHEN 'One year' THEN 10 ELSE 0 END)
        + (CASE WHEN tenure <= 12 THEN 20 WHEN tenure <= 24 THEN 10 ELSE 0 END)
        + (CASE WHEN internet_service = 'Fiber optic' THEN 15 ELSE 0 END)
        + (CASE WHEN payment_method = 'Electronic check' THEN 15 ELSE 0 END)
        + (CASE WHEN tech_support = 'No' THEN 10 ELSE 0 END)
        + (CASE WHEN online_security = 'No' THEN 10 ELSE 0 END)   AS risk_score
    FROM telco_clean c
)
SELECT
    *,
    CASE
        WHEN risk_score >= 70 THEN 'High'
        WHEN risk_score >= 40 THEN 'Medium'
        ELSE                       'Low'
    END AS risk_tier
FROM points;


-- ---------------------------------------------------------------------
-- 2a. Does the score rank customers correctly? Churn rate by tier.
-- ---------------------------------------------------------------------
SELECT
    risk_tier,
    COUNT(*)                                        AS customers,
    SUM(churn_flag)                                 AS churned,
    ROUND(AVG(churn_flag) * 100, 2)                 AS churn_rate_pct,
    ROUND(100.0 * SUM(churn_flag) / SUM(SUM(churn_flag)) OVER (), 2)
                                                    AS pct_of_all_churners
FROM churn_scored
GROUP BY risk_tier
ORDER BY churn_rate_pct DESC;


-- 2b. Treat "High" tier as the model's churn prediction:
--     confusion-matrix metrics.
WITH cm AS (
    SELECT
        SUM(CASE WHEN risk_tier = 'High' AND churn_flag = 1 THEN 1 ELSE 0 END) AS tp,
        SUM(CASE WHEN risk_tier = 'High' AND churn_flag = 0 THEN 1 ELSE 0 END) AS fp,
        SUM(CASE WHEN risk_tier <> 'High' AND churn_flag = 1 THEN 1 ELSE 0 END) AS fn,
        SUM(CASE WHEN risk_tier <> 'High' AND churn_flag = 0 THEN 1 ELSE 0 END) AS tn,
        AVG(churn_flag * 1.0)                                                   AS base_rate
    FROM churn_scored
)
SELECT
    tp, fp, fn, tn,
    ROUND(100.0 * tp / (tp + fp), 2)                   AS precision_pct,
    ROUND(100.0 * tp / (tp + fn), 2)                   AS recall_pct,
    ROUND(100.0 * (tp + tn) / (tp + fp + fn + tn), 2)  AS accuracy_pct,
    ROUND((1.0 * tp / (tp + fp)) / base_rate, 2)       AS lift_vs_random
FROM cm;


-- 2c. Decile table: sort by score, split into 10 groups (gains chart data)
WITH ranked AS (
    SELECT churn_flag,
           NTILE(10) OVER (ORDER BY risk_score DESC, monthly_charges DESC) AS decile
    FROM churn_scored
)
SELECT
    decile,
    COUNT(*)                                       AS customers,
    ROUND(AVG(churn_flag) * 100, 2)                AS churn_rate_pct,
    ROUND(100.0 * SUM(SUM(churn_flag)) OVER (ORDER BY decile)
          / SUM(SUM(churn_flag)) OVER (), 2)       AS cumulative_churners_captured_pct
FROM ranked
GROUP BY decile
ORDER BY decile;


-- ---------------------------------------------------------------------
-- 3. Retention campaign: offer High-risk customers a discount to move
--    to a 1-year contract. Edit the assumptions in the first CTE.
-- ---------------------------------------------------------------------
WITH assumptions AS (
    SELECT
        0.25  AS save_rate,          -- share of would-be churners the offer retains
        0.20  AS discount_pct,       -- discount given to everyone who accepts
        0.40  AS acceptance_rate,    -- share of non-churners who also take the offer
        12    AS horizon_months      -- revenue horizon
),
target AS (
    SELECT
        COUNT(*)                                                     AS targeted,
        SUM(churn_flag)                                              AS expected_churners,
        SUM(CASE WHEN churn_flag = 1 THEN monthly_charges ELSE 0 END) AS churner_mrr,
        SUM(CASE WHEN churn_flag = 0 THEN monthly_charges ELSE 0 END) AS stayer_mrr
    FROM churn_scored
    WHERE risk_tier = 'High'
)
SELECT
    t.targeted,
    t.expected_churners,
    ROUND(t.churner_mrr * a.horizon_months, 0)                              AS revenue_at_risk,
    ROUND(t.expected_churners * a.save_rate, 0)                             AS customers_saved,
    -- revenue kept from saved customers, after their discount
    ROUND(t.churner_mrr * a.save_rate * (1 - a.discount_pct) * a.horizon_months, 0)
                                                                            AS revenue_saved,
    -- discount given away to customers who were never going to leave
    ROUND(t.stayer_mrr * a.acceptance_rate * a.discount_pct * a.horizon_months, 0)
                                                                            AS campaign_cost,
    ROUND(  t.churner_mrr * a.save_rate * (1 - a.discount_pct) * a.horizon_months
          - t.stayer_mrr  * a.acceptance_rate * a.discount_pct * a.horizon_months, 0)
                                                                            AS net_benefit
FROM target t CROSS JOIN assumptions a;

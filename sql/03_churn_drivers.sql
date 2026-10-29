-- =====================================================================
-- 03_churn_drivers.sql
-- Exploratory analysis: what drives churn?
-- Each query answers one business question.
-- =====================================================================

-- Q1. What is the overall churn rate and how much revenue churned?
SELECT
    COUNT(*)                                                   AS customers,
    SUM(churn_flag)                                            AS churned,
    ROUND(AVG(churn_flag) * 100, 2)                            AS churn_rate_pct,
    ROUND(SUM(CASE WHEN churn_flag = 1 THEN monthly_charges ELSE 0 END), 2)
                                                               AS monthly_revenue_lost,
    ROUND(SUM(CASE WHEN churn_flag = 1 THEN monthly_charges ELSE 0 END)
          / SUM(monthly_charges) * 100, 2)                     AS pct_of_revenue_lost
FROM telco_clean;


-- Q2. Churn by contract type (expected strongest driver)
SELECT
    contract,
    COUNT(*)                         AS customers,
    SUM(churn_flag)                  AS churned,
    ROUND(AVG(churn_flag) * 100, 2)  AS churn_rate_pct
FROM telco_clean
GROUP BY contract
ORDER BY churn_rate_pct DESC;


-- Q3. Churn across the customer lifecycle (tenure bands)
SELECT
    tenure_band,
    COUNT(*)                         AS customers,
    ROUND(AVG(churn_flag) * 100, 2)  AS churn_rate_pct,
    ROUND(AVG(monthly_charges), 2)   AS avg_monthly_charge
FROM telco_clean
GROUP BY tenure_band
ORDER BY tenure_band;


-- Q4. Internet service type and churn
SELECT
    internet_service,
    COUNT(*)                         AS customers,
    ROUND(AVG(churn_flag) * 100, 2)  AS churn_rate_pct,
    ROUND(AVG(monthly_charges), 2)   AS avg_monthly_charge
FROM telco_clean
GROUP BY internet_service
ORDER BY churn_rate_pct DESC;


-- Q5. Payment method and churn
SELECT
    payment_method,
    COUNT(*)                         AS customers,
    ROUND(AVG(churn_flag) * 100, 2)  AS churn_rate_pct
FROM telco_clean
GROUP BY payment_method
ORDER BY churn_rate_pct DESC;


-- Q6. Do support/security add-ons protect against churn?
--     (only customers who have internet service)
SELECT 'Tech support'    AS service, tech_support    AS has_service,
       COUNT(*) AS customers, ROUND(AVG(churn_flag) * 100, 2) AS churn_rate_pct
FROM telco_clean WHERE internet_service <> 'No' GROUP BY tech_support
UNION ALL
SELECT 'Online security', online_security,
       COUNT(*), ROUND(AVG(churn_flag) * 100, 2)
FROM telco_clean WHERE internet_service <> 'No' GROUP BY online_security
ORDER BY service, has_service;


-- Q7. Product depth: churn by number of add-on services
SELECT
    addon_count,
    COUNT(*)                         AS customers,
    ROUND(AVG(churn_flag) * 100, 2)  AS churn_rate_pct
FROM telco_clean
GROUP BY addon_count
ORDER BY addon_count;


-- Q8. Demographics
SELECT 'Senior citizen' AS attribute, senior_citizen AS value,
       COUNT(*) AS customers, ROUND(AVG(churn_flag) * 100, 2) AS churn_rate_pct
FROM telco_clean GROUP BY senior_citizen
UNION ALL
SELECT 'Partner', partner, COUNT(*), ROUND(AVG(churn_flag) * 100, 2)
FROM telco_clean GROUP BY partner
UNION ALL
SELECT 'Dependents', dependents, COUNT(*), ROUND(AVG(churn_flag) * 100, 2)
FROM telco_clean GROUP BY dependents
ORDER BY attribute, value;


-- Q9. Two-way view: contract x tenure band (window function for share)
SELECT
    contract,
    tenure_band,
    COUNT(*)                                                     AS customers,
    ROUND(AVG(churn_flag) * 100, 2)                              AS churn_rate_pct,
    ROUND(100.0 * SUM(churn_flag) / SUM(SUM(churn_flag)) OVER (), 2)
                                                                 AS share_of_all_churners_pct
FROM telco_clean
GROUP BY contract, tenure_band
ORDER BY churn_rate_pct DESC;


-- Q10. Which single segment combines the worst risk factors?
SELECT
    contract, internet_service, payment_method,
    COUNT(*)                         AS customers,
    ROUND(AVG(churn_flag) * 100, 2)  AS churn_rate_pct
FROM telco_clean
GROUP BY contract, internet_service, payment_method
HAVING COUNT(*) >= 100
ORDER BY churn_rate_pct DESC
LIMIT 5;

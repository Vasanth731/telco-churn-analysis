-- =====================================================================
-- 02_clean_transform.sql
-- Builds an analysis-ready table: fixes data types, handles missing
-- values and engineers features used throughout the analysis.
-- =====================================================================

DROP TABLE IF EXISTS telco_clean;

CREATE TABLE telco_clean AS
SELECT
    customer_id,
    gender,
    CASE WHEN senior_citizen = 1 THEN 'Yes' ELSE 'No' END            AS senior_citizen,
    partner,
    dependents,
    tenure,
    phone_service,
    multiple_lines,
    internet_service,
    online_security,
    online_backup,
    device_protection,
    tech_support,
    streaming_tv,
    streaming_movies,
    contract,
    paperless_billing,
    payment_method,
    monthly_charges,

    -- Missing-value fix: blank TotalCharges only occurs when tenure = 0,
    -- i.e. the customer has not been billed yet, so 0 is the correct value.
    CASE
        WHEN TRIM(total_charges) = '' OR total_charges IS NULL THEN 0
        ELSE CAST(total_charges AS NUMERIC(10,2))
    END                                                               AS total_charges,

    -- Target as a 0/1 flag so churn rate = AVG(churn_flag)
    CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END                         AS churn_flag,

    -- Feature: tenure bands (customer lifecycle stage)
    CASE
        WHEN tenure <= 12 THEN '0-12 months'
        WHEN tenure <= 24 THEN '13-24 months'
        WHEN tenure <= 48 THEN '25-48 months'
        ELSE                   '49-72 months'
    END                                                               AS tenure_band,

    -- Feature: monthly charge bands
    CASE
        WHEN monthly_charges < 35 THEN 'Low (<35)'
        WHEN monthly_charges < 70 THEN 'Medium (35-70)'
        ELSE                           'High (70+)'
    END                                                               AS charge_band,

    -- Feature: number of add-on services (0-6). More services = stickier.
      (CASE WHEN online_security   = 'Yes' THEN 1 ELSE 0 END)
    + (CASE WHEN online_backup     = 'Yes' THEN 1 ELSE 0 END)
    + (CASE WHEN device_protection = 'Yes' THEN 1 ELSE 0 END)
    + (CASE WHEN tech_support      = 'Yes' THEN 1 ELSE 0 END)
    + (CASE WHEN streaming_tv      = 'Yes' THEN 1 ELSE 0 END)
    + (CASE WHEN streaming_movies  = 'Yes' THEN 1 ELSE 0 END)        AS addon_count,

    -- Feature: automatic vs manual payment
    CASE WHEN payment_method LIKE '%automatic%' THEN 'Automatic' ELSE 'Manual' END
                                                                      AS payment_type,

    -- Feature: annual revenue the customer represents
    monthly_charges * 12                                              AS annual_revenue
FROM telco_raw;

-- ---------------------------------------------------------------------
-- Validation
-- ---------------------------------------------------------------------
SELECT COUNT(*)                                   AS rows_clean,
       SUM(CASE WHEN total_charges IS NULL THEN 1 ELSE 0 END) AS null_total_charges,
       MIN(tenure) AS min_tenure, MAX(tenure) AS max_tenure,
       ROUND(AVG(churn_flag) * 100, 2)            AS churn_rate_pct
FROM telco_clean;

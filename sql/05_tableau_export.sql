-- =====================================================================
-- 05_tableau_export.sql
-- One flat, customer-level view for Tableau. Connect Tableau to this
-- view (PostgreSQL connector) or export it to CSV.
-- =====================================================================

DROP VIEW IF EXISTS vw_churn_dashboard;

CREATE VIEW vw_churn_dashboard AS
SELECT
    customer_id,
    gender,
    senior_citizen,
    partner,
    dependents,
    tenure,
    tenure_band,
    contract,
    internet_service,
    tech_support,
    online_security,
    payment_method,
    payment_type,
    paperless_billing,
    addon_count,
    monthly_charges,
    charge_band,
    total_charges,
    annual_revenue,
    churn_flag,
    CASE WHEN churn_flag = 1 THEN 'Churned' ELSE 'Retained' END AS churn_status,
    risk_score,
    risk_tier
FROM churn_scored;

-- Export to CSV for Tableau Public (which cannot connect to databases):

-- PostgreSQL (psql):
-- \copy (SELECT * FROM vw_churn_dashboard) TO 'tableau/churn_dashboard_data.csv' WITH (FORMAT csv, HEADER true);

-- DuckDB:
COPY (SELECT * FROM vw_churn_dashboard) TO 'tableau/churn_dashboard_data.csv' (HEADER, DELIMITER ',');

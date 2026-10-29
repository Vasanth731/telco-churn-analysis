-- =====================================================================
-- 01_create_and_load.sql
-- Customer Churn Analysis — raw table creation and data load
-- Dialect: PostgreSQL (also runs in DuckDB). Notes for MySQL inline.
-- Dataset: IBM Telco Customer Churn (7,043 customers, 21 columns)
-- =====================================================================

DROP TABLE IF EXISTS telco_raw;

-- TotalCharges is loaded as text on purpose: 11 rows contain a blank
-- string (brand-new customers with tenure = 0). It is fixed in 02_clean.sql.
CREATE TABLE telco_raw (
    customer_id        VARCHAR(20) PRIMARY KEY,
    gender             VARCHAR(10),
    senior_citizen     INTEGER,          -- 0 / 1
    partner            VARCHAR(5),
    dependents         VARCHAR(5),
    tenure             INTEGER,          -- months with the company
    phone_service      VARCHAR(5),
    multiple_lines     VARCHAR(25),
    internet_service   VARCHAR(20),      -- DSL / Fiber optic / No
    online_security    VARCHAR(25),
    online_backup      VARCHAR(25),
    device_protection  VARCHAR(25),
    tech_support       VARCHAR(25),
    streaming_tv       VARCHAR(25),
    streaming_movies   VARCHAR(25),
    contract           VARCHAR(20),      -- Month-to-month / One year / Two year
    paperless_billing  VARCHAR(5),
    payment_method     VARCHAR(40),
    monthly_charges    NUMERIC(10,2),
    total_charges      VARCHAR(20),
    churn              VARCHAR(5)        -- Yes / No
);

-- ---------------------------------------------------------------------
-- Load the CSV (pick the command for your database)
-- ---------------------------------------------------------------------

-- PostgreSQL (psql client):
-- \copy telco_raw FROM 'data/Telco-Customer-Churn.csv' WITH (FORMAT csv, HEADER true);

-- DuckDB:
COPY telco_raw FROM 'data/Telco-Customer-Churn.csv' (HEADER, DELIMITER ',');

-- MySQL:
-- LOAD DATA LOCAL INFILE 'data/Telco-Customer-Churn.csv'
-- INTO TABLE telco_raw
-- FIELDS TERMINATED BY ',' ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS;

-- ---------------------------------------------------------------------
-- Sanity checks
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS row_count FROM telco_raw;                      -- expect 7043

SELECT COUNT(*) AS blank_total_charges
FROM telco_raw
WHERE TRIM(total_charges) = '' OR total_charges IS NULL;          -- expect 11

SELECT COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_ids
FROM telco_raw;                                                   -- expect 0

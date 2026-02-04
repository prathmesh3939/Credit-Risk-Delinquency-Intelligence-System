/* ============================================================
   CREDIT RISK & DELINQUENCY INTELLIGENCE SYSTEM
   Database  : MySQL
   Purpose   : End-to-end credit risk analytics data pipeline
   Author    : Prathmesh Patil
   ============================================================ */


/* ============================================================
   1. DATABASE SETUP
   ============================================================ */

CREATE DATABASE IF NOT EXISTS credit_risk_system;
USE credit_risk_system;


/* ============================================================
   2. MASTER & FACT TABLES (SCHEMA LAYER)
   ============================================================ */

-- -------------------------------
-- Customers (Dimension)
-- -------------------------------
CREATE TABLE IF NOT EXISTS customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100),
    date_of_birth DATE,
    gender VARCHAR(10),
    city VARCHAR(50),
    state VARCHAR(50),
    income_band VARCHAR(30),
    occupation VARCHAR(50),
    account_open_date DATE
);

-- -------------------------------
-- Credit Accounts (Dimension)
-- -------------------------------
CREATE TABLE IF NOT EXISTS credit_accounts (
    account_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    credit_limit DECIMAL(10,2),
    interest_rate DECIMAL(5,2),
    account_status VARCHAR(20),
    open_date DATE,
    close_date DATE,
    CONSTRAINT fk_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
);

-- -------------------------------
-- Billing Statements (Fact)
-- -------------------------------
CREATE TABLE IF NOT EXISTS billing_statements (
    statement_id INT AUTO_INCREMENT PRIMARY KEY,
    account_id INT NOT NULL,
    billing_cycle DATE,
    bill_date DATE,
    due_date DATE,
    total_bill_amount DECIMAL(10,2),
    minimum_due DECIMAL(10,2),
    CONSTRAINT fk_account_bs
        FOREIGN KEY (account_id)
        REFERENCES credit_accounts(account_id)
);

-- -------------------------------
-- Payments (Fact)
-- -------------------------------
CREATE TABLE IF NOT EXISTS payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    account_id INT NOT NULL,
    payment_date DATE,
    payment_amount DECIMAL(10,2),
    payment_channel VARCHAR(30),
    CONSTRAINT fk_account_pay
        FOREIGN KEY (account_id)
        REFERENCES credit_accounts(account_id)
);


/* ============================================================
   3. CONTROLLED DATA RESET (DEV / QA SAFE)
   ============================================================ */

SET SQL_SAFE_UPDATES = 0;

DELETE FROM payments;
DELETE FROM billing_statements;
DELETE FROM credit_accounts;
DELETE FROM customers;

SET SQL_SAFE_UPDATES = 1;


/* ============================================================
   4. SEQUENCE / NUMBERS TABLE (DATA ENGINEERING UTILITY)
   ============================================================ */

CREATE TABLE IF NOT EXISTS numbers (
    n INT PRIMARY KEY
);

-- Populate 1 to 1000 deterministically
DELETE FROM numbers;

INSERT INTO numbers (n)
SELECT a.n + b.n * 10 + c.n * 100 + 1
FROM
(SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
(SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b,
(SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) c
WHERE a.n + b.n * 10 + c.n * 100 < 1000;


/* ============================================================
   5. DATA LOAD (SIMULATED INDUSTRY BEHAVIOR)
   ============================================================ */

-- -------------------------------
-- Customers
-- -------------------------------
INSERT INTO customers (
    customer_name, date_of_birth, gender, city, state,
    income_band, occupation, account_open_date
)
SELECT
    CONCAT('Customer_', n),
    DATE_SUB('1994-01-01', INTERVAL FLOOR(RAND()*9000) DAY),
    IF(RAND() > 0.5, 'Male', 'Female'),
    ELT(FLOOR(1 + RAND()*5),'Pune','Mumbai','Delhi','Bangalore','Hyderabad'),
    ELT(FLOOR(1 + RAND()*5),'MH','MH','DL','KA','TS'),
    ELT(FLOOR(1 + RAND()*4),'Low','Medium','High','Very High'),
    ELT(FLOOR(1 + RAND()*4),'Salaried','Self-Employed','Business','Student'),
    DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND()*1500) DAY)
FROM numbers;

-- -------------------------------
-- Credit Accounts (1 per customer)
-- -------------------------------
INSERT INTO credit_accounts (
    customer_id, credit_limit, interest_rate,
    account_status, open_date, close_date
)
SELECT
    customer_id,
    ELT(FLOOR(1 + RAND()*4), 50000, 100000, 200000, 300000),
    ROUND(12 + RAND()*8, 2),
    'ACTIVE',
    account_open_date,
    NULL
FROM customers;

-- -------------------------------
-- Billing Statements (12 months)
-- -------------------------------
INSERT INTO billing_statements (
    account_id, billing_cycle, bill_date, due_date,
    total_bill_amount, minimum_due
)
SELECT
    ca.account_id,
    DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL m.month_offset MONTH), '%Y-%m-01'),
    DATE_SUB(CURDATE(), INTERVAL m.month_offset MONTH),
    DATE_ADD(DATE_SUB(CURDATE(), INTERVAL m.month_offset MONTH), INTERVAL 15 DAY),
    ROUND(2000 + RAND()*50000, 2),
    ROUND((2000 + RAND()*50000) * 0.10, 2)
FROM credit_accounts ca
JOIN (
    SELECT 0 month_offset UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL
    SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL
    SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL
    SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11
) m;

-- -------------------------------
-- Payments (Realistic behavior)
-- -------------------------------
INSERT INTO payments (
    account_id, payment_date, payment_amount, payment_channel
)
SELECT
    bs.account_id,
    DATE_ADD(bs.due_date, INTERVAL FLOOR(RAND()*45 - 10) DAY),
    CASE WHEN RAND() < 0.65 THEN bs.total_bill_amount ELSE bs.minimum_due END,
    ELT(FLOOR(1 + RAND()*4),'UPI','NetBanking','Debit Card','Auto-Debit')
FROM billing_statements bs;


/* ============================================================
   6. DELINQUENCY & DPD ENGINE
   ============================================================ */

-- -------------------------------
-- Snapshot Table
-- -------------------------------
CREATE TABLE IF NOT EXISTS delinquency_snapshot (
    account_id INT,
    billing_cycle DATE,
    due_date DATE,
    payment_date DATE,
    days_past_due INT,
    delinquency_bucket VARCHAR(20),
    is_delinquent TINYINT,
    PRIMARY KEY (account_id, billing_cycle)
);

SET SQL_SAFE_UPDATES = 0;
DELETE FROM delinquency_snapshot;
SET SQL_SAFE_UPDATES = 1;

-- -------------------------------
-- Normalize payments (1 per cycle)
-- -------------------------------
CREATE OR REPLACE VIEW cycle_payments AS
SELECT
    bs.account_id,
    bs.billing_cycle,
    MIN(p.payment_date) AS payment_date
FROM billing_statements bs
JOIN payments p
  ON bs.account_id = p.account_id
 AND p.payment_date >= bs.bill_date
GROUP BY bs.account_id, bs.billing_cycle;

-- -------------------------------
-- Populate Delinquency Snapshot
-- -------------------------------
INSERT INTO delinquency_snapshot (
    account_id, billing_cycle, due_date, payment_date,
    days_past_due, delinquency_bucket, is_delinquent
)
SELECT
    bs.account_id,
    bs.billing_cycle,
    bs.due_date,
    cp.payment_date,
    CASE WHEN cp.payment_date <= bs.due_date THEN 0
         ELSE DATEDIFF(cp.payment_date, bs.due_date) END,
    CASE
        WHEN cp.payment_date <= bs.due_date THEN 'On-Time'
        WHEN DATEDIFF(cp.payment_date, bs.due_date) BETWEEN 1 AND 30 THEN 'Mild'
        WHEN DATEDIFF(cp.payment_date, bs.due_date) BETWEEN 31 AND 60 THEN 'Moderate'
        WHEN DATEDIFF(cp.payment_date, bs.due_date) BETWEEN 61 AND 90 THEN 'Severe'
        ELSE 'Default'
    END,
    CASE WHEN cp.payment_date > bs.due_date THEN 1 ELSE 0 END
FROM billing_statements bs
JOIN cycle_payments cp
  ON bs.account_id = cp.account_id
 AND bs.billing_cycle = cp.billing_cycle;


/* ============================================================
   7. ACCOUNT-LEVEL RISK FEATURES
   ============================================================ */

CREATE TABLE IF NOT EXISTS account_risk_features (
    account_id INT PRIMARY KEY,
    avg_dpd DECIMAL(6,2),
    max_dpd INT,
    delinquency_ratio DECIMAL(5,2),
    severe_delinquency_count INT,
    default_like_cycles INT,
    recent_avg_dpd_3m DECIMAL(6,2),
    delinquency_streak INT
);

-- Base aggregations
INSERT INTO account_risk_features
SELECT
    account_id,
    ROUND(AVG(days_past_due),2),
    MAX(days_past_due),
    ROUND(SUM(is_delinquent)/COUNT(*),2),
    SUM(CASE WHEN days_past_due > 60 THEN 1 ELSE 0 END),
    SUM(CASE WHEN days_past_due >= 90 THEN 1 ELSE 0 END),
    ROUND(AVG(CASE WHEN billing_cycle >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
              THEN days_past_due END),2),
    0
FROM delinquency_snapshot
GROUP BY account_id;

-- Delinquency streak logic
CREATE TEMPORARY TABLE delinquency_flags AS
SELECT
    account_id,
    billing_cycle,
    is_delinquent,
    ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY billing_cycle) -
    ROW_NUMBER() OVER (PARTITION BY account_id, is_delinquent ORDER BY billing_cycle) AS grp
FROM delinquency_snapshot;

UPDATE account_risk_features arf
JOIN (
    SELECT account_id, MAX(cnt) AS max_streak
    FROM (
        SELECT account_id, grp, COUNT(*) cnt
        FROM delinquency_flags
        WHERE is_delinquent = 1
        GROUP BY account_id, grp
    ) x
    GROUP BY account_id
) s
ON arf.account_id = s.account_id
SET arf.delinquency_streak = s.max_streak;

SELECT COUNT(*) FROM account_risk_features;


SET SQL_SAFE_UPDATES = 0;
DELETE FROM account_risk_features;
SET SQL_SAFE_UPDATES = 1;


SET SQL_SAFE_UPDATES = 0;

DELETE FROM account_risk_features;

SELECT COUNT(*) AS remaining_rows FROM account_risk_features;

SET SQL_SAFE_UPDATES = 1;

INSERT INTO account_risk_features (
    account_id,
    avg_dpd,
    max_dpd,
    delinquency_ratio,
    severe_delinquency_count,
    default_like_cycles,
    recent_avg_dpd_3m,
    delinquency_streak
)
SELECT
    account_id,
    ROUND(AVG(days_past_due),2),
    MAX(days_past_due),
    ROUND(SUM(is_delinquent)/COUNT(*),2),
    SUM(CASE WHEN days_past_due > 60 THEN 1 ELSE 0 END),
    SUM(CASE WHEN days_past_due >= 90 THEN 1 ELSE 0 END),
    ROUND(AVG(CASE
        WHEN billing_cycle >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
        THEN days_past_due
    END),2),
    0
FROM delinquency_snapshot
GROUP BY account_id;



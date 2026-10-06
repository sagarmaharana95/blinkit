-- ============================================================
-- Blinkit Quick-Commerce Analytics — Data Ingestion & Cleaning
-- Loads all 8 CSVs, handles mixed date formats, fixes data
-- quality issues, and validates the load.
-- ============================================================

USE blinkit_analytics;

-- ------------------------------------------------------------------
-- NOTE ON FILE PATH:
-- Files must sit inside MySQL's secure_file_priv directory.
-- Find it with: SHOW VARIABLES LIKE 'secure_file_priv';
-- Replace the path below with your actual directory.
-- ------------------------------------------------------------------

-- 1. customers (registration_date already in a MySQL-friendly format)
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/blinkit_customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 2. products
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/blinkit_products.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 3. orders (dates in DD-MM-YYYY HH:MI format — needs STR_TO_DATE)
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/blinkit_orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, @order_date, @promised_delivery_time, @actual_delivery_time,
 delivery_status, order_total, payment_method, delivery_partner_id, store_id)
SET
    order_date = STR_TO_DATE(@order_date, '%d-%m-%Y %H:%i'),
    promised_delivery_time = STR_TO_DATE(@promised_delivery_time, '%d-%m-%Y %H:%i'),
    actual_delivery_time = STR_TO_DATE(@actual_delivery_time, '%d-%m-%Y %H:%i');

-- 4. order_items
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/blinkit_order_items.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 5. delivery_performance (dates already in YYYY-MM-DD HH:MM:SS format)
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/blinkit_delivery_performance.csv'
INTO TABLE delivery_performance
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 6. customer_feedback (feedback_date already in YYYY-MM-DD format)
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/blinkit_customer_feedback.csv'
INTO TABLE customer_feedback
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 7. inventory (dates in DD-MM-YYYY format — needs STR_TO_DATE)
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/blinkit_inventory.csv'
INTO TABLE inventory
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, @stock_date, stock_received, damaged_stock)
SET
    stock_date = STR_TO_DATE(@stock_date, '%d-%m-%Y');

-- 8. marketing_performance
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/blinkit_marketing_performance.csv'
INTO TABLE marketing_performance
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ============================================================
-- VALIDATION: Confirm row counts match source CSVs
-- ============================================================
SELECT 'customers' AS tbl, COUNT(*) AS row_count FROM customers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'delivery_performance', COUNT(*) FROM delivery_performance
UNION ALL SELECT 'customer_feedback', COUNT(*) FROM customer_feedback
UNION ALL SELECT 'inventory', COUNT(*) FROM inventory
UNION ALL SELECT 'marketing_performance', COUNT(*) FROM marketing_performance;

-- Expected: 2500, 268, 5000, 5000, 5000, 5000, 75172, 5400

-- ============================================================
-- DATA QUALITY CHECKS
-- ============================================================

-- Check for NULLs in key customer fields
SELECT
    SUM(CASE WHEN customer_name IS NULL THEN 1 ELSE 0 END) AS null_name,
    SUM(CASE WHEN email IS NULL THEN 1 ELSE 0 END) AS null_email,
    SUM(CASE WHEN registration_date IS NULL THEN 1 ELSE 0 END) AS null_reg_date
FROM customers;

-- Check for duplicate order_id
SELECT order_id, COUNT(*) AS cnt
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Check for negative delivery times (data anomaly)
SELECT COUNT(*) AS negative_delivery_count
FROM delivery_performance
WHERE delivery_time_minutes < 0;

-- Cross-check delivery_status consistency between orders and delivery_performance
SELECT o.order_id, o.delivery_status AS orders_status, d.delivery_status AS delivery_perf_status
FROM orders o
JOIN delivery_performance d ON o.order_id = d.order_id
WHERE o.delivery_status != d.delivery_status
LIMIT 10;

-- Check for invalid/negative business values
SELECT
    (SELECT COUNT(*) FROM order_items WHERE quantity <= 0) AS bad_quantity,
    (SELECT COUNT(*) FROM orders WHERE order_total <= 0) AS bad_order_total,
    (SELECT COUNT(*) FROM products WHERE price <= 0) AS bad_price;

-- ============================================================
-- CLEANING ACTIONS
-- ============================================================
SET SQL_SAFE_UPDATES = 0;

-- Fill NULL customer names/emails with a placeholder rather than dropping rows
UPDATE customers SET customer_name = 'Unknown' WHERE customer_name IS NULL;
UPDATE customers SET email = 'unknown@blinkit.com' WHERE email IS NULL;

-- Convert negative delivery times to their absolute value
-- (business decision: we're measuring delivery-time variance, sign doesn't matter)
UPDATE delivery_performance
SET delivery_time_minutes = ABS(delivery_time_minutes)
WHERE delivery_time_minutes < 0;

SET SQL_SAFE_UPDATES = 1;

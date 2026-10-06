-- ============================================================
-- Blinkit Quick-Commerce Analytics — Schema Creation
-- Creates the database and all 8 relational tables with
-- primary/foreign key constraints.
-- ============================================================

CREATE DATABASE IF NOT EXISTS blinkit_analytics;
USE blinkit_analytics;

-- ---------------------------------------------------------
-- 1. customers
-- ---------------------------------------------------------
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(15),
    address VARCHAR(255),
    area VARCHAR(100),
    pincode VARCHAR(10),
    registration_date DATE,
    customer_segment VARCHAR(50),
    total_orders INT,
    avg_order_value DECIMAL(10,2)
);

-- ---------------------------------------------------------
-- 2. products
-- ---------------------------------------------------------
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(150),
    category VARCHAR(100),
    brand VARCHAR(100),
    price DECIMAL(10,2),
    mrp DECIMAL(10,2),
    margin_percentage DECIMAL(5,2),
    shelf_life_days INT,
    min_stock_level INT,
    max_stock_level INT
);

-- ---------------------------------------------------------
-- 3. orders
-- Note: order_id is BIGINT because the source data uses
-- 10-digit synthetic order IDs that overflow a standard INT.
-- ---------------------------------------------------------
CREATE TABLE orders (
    order_id BIGINT PRIMARY KEY,
    customer_id INT,
    order_date DATETIME,
    promised_delivery_time DATETIME,
    actual_delivery_time DATETIME,
    delivery_status VARCHAR(50),
    order_total DECIMAL(10,2),
    payment_method VARCHAR(50),
    delivery_partner_id INT,
    store_id INT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- ---------------------------------------------------------
-- 4. order_items
-- ---------------------------------------------------------
CREATE TABLE order_items (
    order_id BIGINT,
    product_id INT,
    quantity INT,
    unit_price DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- ---------------------------------------------------------
-- 5. delivery_performance
-- ---------------------------------------------------------
CREATE TABLE delivery_performance (
    order_id BIGINT,
    delivery_partner_id INT,
    promised_time DATETIME,
    actual_time DATETIME,
    delivery_time_minutes DECIMAL(6,2),
    distance_km DECIMAL(6,2),
    delivery_status VARCHAR(50),
    reasons_if_delayed VARCHAR(255),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- ---------------------------------------------------------
-- 6. customer_feedback
-- ---------------------------------------------------------
CREATE TABLE customer_feedback (
    feedback_id INT PRIMARY KEY,
    order_id BIGINT,
    customer_id INT,
    rating INT,
    feedback_text TEXT,
    feedback_category VARCHAR(100),
    sentiment VARCHAR(50),
    feedback_date DATE,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- ---------------------------------------------------------
-- 7. inventory
-- Note: "date" is renamed to "stock_date" since DATE is a
-- reserved keyword in MySQL.
-- ---------------------------------------------------------
CREATE TABLE inventory (
    product_id INT,
    stock_date DATE,
    stock_received INT,
    damaged_stock INT,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- ---------------------------------------------------------
-- 8. marketing_performance
-- Note: "date" renamed to "campaign_date" for the same reason.
-- Standalone table — no FK to orders (campaign-level data only).
-- ---------------------------------------------------------
CREATE TABLE marketing_performance (
    campaign_id INT,
    campaign_name VARCHAR(150),
    campaign_date DATE,
    target_audience VARCHAR(100),
    channel VARCHAR(50),
    impressions INT,
    clicks INT,
    conversions INT,
    spend DECIMAL(10,2),
    revenue_generated DECIMAL(10,2),
    roas DECIMAL(6,2)
);

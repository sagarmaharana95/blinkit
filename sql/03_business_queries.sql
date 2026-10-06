-- ============================================================
-- Blinkit Quick-Commerce Analytics — Advanced Business Queries
-- Uses CTEs and window functions (DENSE_RANK, LAG, NTILE) to
-- answer the 3 core business questions:
--   1. Delivery Efficiency
--   2. Revenue Risk
--   3. Customer Value / Cohorts
-- ============================================================

USE blinkit_analytics;

-- ============================================================
-- SECTION 1: DELIVERY EFFICIENCY
-- ============================================================

-- 1.1 Confirm the distinct delivery status values
SELECT DISTINCT delivery_status FROM orders;

-- 1.2 SLA breach % by store — which stores have the worst delivery record
SELECT
    store_id,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN delivery_status IN ('Slightly Delayed', 'Significantly Delayed') THEN 1 ELSE 0 END) AS delayed_orders,
    ROUND(SUM(CASE WHEN delivery_status IN ('Slightly Delayed', 'Significantly Delayed') THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS sla_breach_pct
FROM orders
GROUP BY store_id
ORDER BY sla_breach_pct DESC
LIMIT 10;

-- 1.3 Overall delivery status breakdown (executive KPI)
SELECT
    delivery_status,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2) AS pct_of_total
FROM orders
GROUP BY delivery_status
ORDER BY order_count DESC;


-- ============================================================
-- SECTION 2: REVENUE RISK
-- (No explicit "Cancelled" status exists in this dataset, so
--  revenue risk is measured via delivery delays and negative
--  customer sentiment instead.)
-- ============================================================

-- 2.1 Revenue-at-risk by payment method (severely delayed orders)
SELECT
    payment_method,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN delivery_status = 'Significantly Delayed' THEN 1 ELSE 0 END) AS severely_delayed_orders,
    ROUND(SUM(order_total), 2) AS total_revenue,
    ROUND(SUM(CASE WHEN delivery_status = 'Significantly Delayed' THEN order_total ELSE 0 END), 2) AS revenue_at_risk
FROM orders
GROUP BY payment_method
ORDER BY revenue_at_risk DESC;

-- 2.2 Revenue tied to negative customer sentiment — direct churn-risk exposure
SELECT
    cf.sentiment,
    COUNT(DISTINCT cf.order_id) AS orders_with_feedback,
    ROUND(AVG(cf.rating), 2) AS avg_rating,
    ROUND(SUM(o.order_total), 2) AS associated_revenue
FROM customer_feedback cf
JOIN orders o ON cf.order_id = o.order_id
GROUP BY cf.sentiment
ORDER BY associated_revenue DESC;


-- ============================================================
-- SECTION 3: CUSTOMER VALUE / COHORTS
-- ============================================================

-- 3.1 Top 3 highest-spending customers per segment (DENSE_RANK window function)
SELECT *
FROM (
    SELECT
        c.customer_id,
        c.customer_name,
        c.customer_segment,
        SUM(o.order_total) AS total_spend,
        DENSE_RANK() OVER (PARTITION BY c.customer_segment ORDER BY SUM(o.order_total) DESC) AS spend_rank
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name, c.customer_segment
) ranked
WHERE spend_rank <= 3
ORDER BY customer_segment, spend_rank;

-- 3.2 Month-over-month revenue growth (CTE + LAG window function)
WITH monthly_orders AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS order_month,
        COUNT(*) AS total_orders,
        SUM(order_total) AS total_revenue
    FROM orders
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT
    order_month,
    total_orders,
    total_revenue,
    LAG(total_revenue) OVER (ORDER BY order_month) AS prev_month_revenue,
    ROUND(
        (total_revenue - LAG(total_revenue) OVER (ORDER BY order_month)) * 100.0
        / LAG(total_revenue) OVER (ORDER BY order_month), 2
    ) AS mom_growth_pct
FROM monthly_orders
ORDER BY order_month;

-- 3.3 Segment-wise performance — do pre-assigned labels match actual behaviour?
SELECT
    customer_segment,
    COUNT(DISTINCT c.customer_id) AS num_customers,
    ROUND(AVG(c.total_orders), 2) AS avg_orders_per_customer,
    ROUND(AVG(c.avg_order_value), 2) AS avg_order_value,
    ROUND(SUM(o.order_total), 2) AS segment_total_revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY customer_segment
ORDER BY segment_total_revenue DESC;

-- 3.4 Revenue concentration — Pareto check using NTILE window function
WITH customer_revenue AS (
    SELECT
        c.customer_id,
        c.customer_name,
        SUM(o.order_total) AS total_spend,
        NTILE(5) OVER (ORDER BY SUM(o.order_total) DESC) AS revenue_quintile
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name
)
SELECT
    revenue_quintile,
    COUNT(*) AS num_customers,
    ROUND(SUM(total_spend), 2) AS quintile_revenue,
    ROUND(SUM(total_spend) * 100.0 / (SELECT SUM(order_total) FROM orders), 2) AS pct_of_total_revenue
FROM customer_revenue
GROUP BY revenue_quintile
ORDER BY revenue_quintile;


-- ============================================================
-- SECTION 4: SUPPORTING ANALYSIS (category & marketing)
-- ============================================================

-- 4.1 Revenue by product category
SELECT
    p.category,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS category_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY category_revenue DESC;

-- 4.2 Marketing channel efficiency (ROAS comparison)
SELECT
    channel,
    ROUND(SUM(spend), 2) AS total_spend,
    ROUND(SUM(revenue_generated), 2) AS total_revenue,
    ROUND(AVG(roas), 2) AS avg_roas
FROM marketing_performance
GROUP BY channel
ORDER BY avg_roas DESC;

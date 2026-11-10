-- ============================================================
-- E-Commerce Analytics Platform
-- Module: Customer Analytics & Purchasing Behaviour
-- Script: sql/03_customer_analysis.sql
-- Dataset: Brazilian E-Commerce Public Dataset by Olist
-- ============================================================

USE ecommerce_analytics;

-- ============================================================
-- 1. Customer Purchase Frequency Distribution
-- Demonstrates: Grouping by natural customer entity (customer_unique_id)
-- ============================================================
WITH customer_order_counts AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT 
    total_orders,
    COUNT(customer_unique_id) AS customer_count,
    ROUND(COUNT(customer_unique_id) / (SELECT COUNT(*) FROM customer_order_counts) * 100, 2) AS pct_of_customer_base,
    CASE 
        WHEN total_orders = 1 THEN '1 Order (One-Time)'
        WHEN total_orders = 2 THEN '2 Orders (Repeat)'
        WHEN total_orders BETWEEN 3 AND 5 THEN '3-5 Orders (Frequent)'
        ELSE '6+ Orders (VIP Power Buyer)'
    END AS buyer_tier
FROM customer_order_counts
GROUP BY total_orders
ORDER BY total_orders ASC;


-- ============================================================
-- 2. Repeat Customer Rate
-- Executive KPI: % of customers who made more than 1 delivered purchase
-- ============================================================
WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS orders_count
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT 
    COUNT(*)                                                         AS total_purchasing_customers,
    SUM(CASE WHEN orders_count > 1 THEN 1 ELSE 0 END)                AS repeat_customers,
    SUM(CASE WHEN orders_count = 1 THEN 1 ELSE 0 END)                AS one_time_customers,
    ROUND(
        SUM(CASE WHEN orders_count > 1 THEN 1 ELSE 0 END) / COUNT(*) * 100, 
        2
    )                                                                AS repeat_customer_rate_pct,
    ROUND(
        SUM(CASE WHEN orders_count = 1 THEN 1 ELSE 0 END) / COUNT(*) * 100, 
        2
    )                                                                AS one_time_customer_rate_pct
FROM customer_orders;


-- ============================================================
-- 3. Revenue Contribution: One-Time vs Repeat Customers
-- Compares financial impact of customer retention
-- ============================================================
WITH customer_frequency AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS orders_count,
        SUM(oi.price) AS total_spend
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
classified_customers AS (
    SELECT 
        customer_unique_id,
        orders_count,
        total_spend,
        CASE 
            WHEN orders_count > 1 THEN 'Repeat Customer' 
            ELSE 'One-Time Customer' 
        END AS customer_type
    FROM customer_frequency
)
SELECT 
    customer_type,
    COUNT(customer_unique_id)                   AS customer_count,
    ROUND(COUNT(customer_unique_id) / SUM(COUNT(customer_unique_id)) OVER () * 100, 2) AS customer_share_pct,
    ROUND(SUM(total_spend), 2)                  AS total_revenue,
    ROUND(SUM(total_spend) / SUM(SUM(total_spend)) OVER () * 100, 2) AS revenue_share_pct,
    ROUND(AVG(total_spend), 2)                  AS average_clv
FROM classified_customers
GROUP BY customer_type;


-- ============================================================
-- 4. Customer Lifetime Value (CLV) - Top 20 Customers
-- Demonstrates: Complex multi-table customer metrics and Window RANK()
-- ============================================================
WITH customer_stats AS (
    SELECT 
        c.customer_unique_id,
        c.customer_state,
        c.customer_city,
        COUNT(DISTINCT o.order_id) AS lifetime_orders,
        COUNT(oi.order_item_id)    AS total_items_bought,
        ROUND(SUM(oi.price), 2)    AS lifetime_spend,
        MIN(o.order_purchase_timestamp) AS first_order_date,
        MAX(o.order_purchase_timestamp) AS latest_order_date
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id, c.customer_state, c.customer_city
)
SELECT 
    customer_unique_id,
    customer_state,
    customer_city,
    lifetime_orders,
    total_items_bought,
    lifetime_spend,
    ROUND(lifetime_spend / lifetime_orders, 2) AS avg_order_value,
    DATEDIFF(latest_order_date, first_order_date) AS customer_lifespan_days,
    DENSE_RANK() OVER (ORDER BY lifetime_spend DESC) AS spend_rank
FROM customer_stats
ORDER BY lifetime_spend DESC
LIMIT 20;


-- ============================================================
-- 5. Customer Spend Distribution (Quartiles via NTILE)
-- Demonstrates: Statistical distribution analysis
-- ============================================================
WITH customer_spend AS (
    SELECT 
        c.customer_unique_id,
        ROUND(SUM(oi.price), 2) AS total_spend
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
spend_quartiles AS (
    SELECT 
        customer_unique_id,
        total_spend,
        NTILE(4) OVER (ORDER BY total_spend ASC) AS spend_quartile
    FROM customer_spend
)
SELECT 
    spend_quartile,
    CASE 
        WHEN spend_quartile = 1 THEN 'Q1 - Low Spender (0-25%)'
        WHEN spend_quartile = 2 THEN 'Q2 - Moderate Spender (25-50%)'
        WHEN spend_quartile = 3 THEN 'Q3 - High Spender (50-75%)'
        WHEN spend_quartile = 4 THEN 'Q4 - VIP / Top Spender (75-100%)'
    END AS quartile_label,
    COUNT(*)               AS customer_count,
    ROUND(MIN(total_spend), 2) AS min_spend_in_tier,
    ROUND(MAX(total_spend), 2) AS max_spend_in_tier,
    ROUND(AVG(total_spend), 2) AS avg_spend_in_tier,
    ROUND(SUM(total_spend), 2) AS total_revenue_generated
FROM spend_quartiles
GROUP BY spend_quartile
ORDER BY spend_quartile ASC;


-- ============================================================
-- 6. Value-Based Customer Segmentation
-- ============================================================
WITH customer_value AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS orders_count,
        ROUND(SUM(oi.price), 2) AS monetary_spend
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT 
    CASE 
        WHEN monetary_spend >= 1000 AND orders_count >= 2 THEN 'Platinum VIP'
        WHEN monetary_spend >= 500  THEN 'Gold High-Value'
        WHEN monetary_spend >= 200  THEN 'Silver Mid-Value'
        WHEN monetary_spend >= 75   THEN 'Bronze Standard'
        ELSE 'Entry Budget'
    END AS customer_value_segment,
    COUNT(*)                                              AS customers,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM customer_value) * 100, 2) AS customer_pct,
    ROUND(SUM(monetary_spend), 2)                         AS total_revenue,
    ROUND(SUM(monetary_spend) / SUM(SUM(monetary_spend)) OVER () * 100, 2) AS revenue_share_pct,
    ROUND(AVG(monetary_spend), 2)                         AS avg_spend
FROM customer_value
GROUP BY customer_value_segment
ORDER BY total_revenue DESC;


-- ============================================================
-- 7. New Customer Cohort Acquisition by Month
-- Demonstrates: Identifying first purchase timestamp per natural customer
-- ============================================================
WITH first_purchases AS (
    SELECT 
        c.customer_unique_id,
        MIN(o.order_purchase_timestamp) AS first_order_date
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT 
    DATE_FORMAT(first_order_date, '%Y-%m') AS cohort_month,
    COUNT(customer_unique_id)              AS new_customers_acquired,
    SUM(COUNT(customer_unique_id)) OVER (
        ORDER BY DATE_FORMAT(first_order_date, '%Y-%m')
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                      AS cumulative_customer_base
FROM first_purchases
GROUP BY DATE_FORMAT(first_order_date, '%Y-%m')
ORDER BY cohort_month ASC;

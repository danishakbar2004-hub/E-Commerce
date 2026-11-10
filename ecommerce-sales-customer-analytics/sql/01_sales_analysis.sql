-- ============================================================
-- E-Commerce Analytics Platform
-- Module: Sales Performance Analysis
-- Script: sql/01_sales_analysis.sql
-- Dataset: Brazilian E-Commerce Public Dataset by Olist
-- Author: Senior Data Analyst & SQL Specialist
-- ============================================================

USE ecommerce_analytics;

-- ============================================================
-- 1. All-Time KPI Executive Summary
-- Demonstrates: CTEs, aggregate functions, DISTINCT COUNT on natural keys
-- Note: Excludes non-delivered orders to prevent double-counting or fictitious revenue.
-- ============================================================
WITH delivered_orders AS (
    SELECT 
        o.order_id,
        o.customer_id,
        o.order_purchase_timestamp
    FROM orders o
    WHERE o.order_status = 'delivered'
),
delivered_items AS (
    SELECT 
        oi.order_id,
        oi.price,
        oi.freight_value
    FROM order_items oi
    INNER JOIN delivered_orders d_ord ON oi.order_id = d_ord.order_id
)
SELECT 
    COUNT(DISTINCT d_ord.order_id)                                  AS total_delivered_orders,
    COUNT(DISTINCT c.customer_unique_id)                            AS total_unique_customers,
    ROUND(SUM(di.price), 2)                                         AS total_item_revenue,
    ROUND(SUM(di.freight_value), 2)                                 AS total_freight_revenue,
    ROUND(SUM(di.price + di.freight_value), 2)                      AS total_gross_merchandise_value,
    ROUND(SUM(di.price) / COUNT(DISTINCT d_ord.order_id), 2)       AS average_order_value_aov,
    ROUND(SUM(di.price) / COUNT(DISTINCT c.customer_unique_id), 2)  AS revenue_per_customer,
    MIN(d_ord.order_purchase_timestamp)                             AS start_date,
    MAX(d_ord.order_purchase_timestamp)                             AS end_date
FROM delivered_orders d_ord
INNER JOIN customers c ON d_ord.customer_id = c.customer_id
INNER JOIN delivered_items di ON d_ord.order_id = di.order_id;


-- ============================================================
-- 2. Monthly Revenue Trend with Running Cumulative and MoM Growth
-- Demonstrates: DATE functions, CTEs, Window Functions (LAG, SUM OVER ROWS)
-- ============================================================
WITH monthly_metrics AS (
    SELECT 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS year_month,
        YEAR(o.order_purchase_timestamp)                AS sales_year,
        MONTH(o.order_purchase_timestamp)               AS sales_month,
        MONTHNAME(o.order_purchase_timestamp)           AS month_name,
        COUNT(DISTINCT o.order_id)                      AS order_count,
        COUNT(DISTINCT c.customer_unique_id)            AS unique_customers,
        ROUND(SUM(oi.price), 2)                         AS monthly_revenue,
        ROUND(SUM(oi.freight_value), 2)                 AS monthly_freight
    FROM orders o
    INNER JOIN customers c ON o.customer_id = c.customer_id
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m'),
        YEAR(o.order_purchase_timestamp),
        MONTH(o.order_purchase_timestamp),
        MONTHNAME(o.order_purchase_timestamp)
)
SELECT 
    year_month,
    sales_year,
    month_name,
    order_count,
    unique_customers,
    monthly_revenue,
    ROUND(monthly_revenue / order_count, 2) AS monthly_aov,
    -- Previous month revenue using window LAG()
    LAG(monthly_revenue, 1) OVER (ORDER BY year_month) AS previous_month_revenue,
    -- Month-over-Month Revenue Growth Percentage
    ROUND(
        (monthly_revenue - LAG(monthly_revenue, 1) OVER (ORDER BY year_month)) 
        / NULLIF(LAG(monthly_revenue, 1) OVER (ORDER BY year_month), 0) * 100, 
        2
    ) AS mom_growth_pct,
    -- Running Cumulative Revenue
    ROUND(
        SUM(monthly_revenue) OVER (
            ORDER BY year_month 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ), 2
    ) AS cumulative_revenue
FROM monthly_metrics
ORDER BY year_month ASC;


-- ============================================================
-- 3. Year-over-Year (YoY) Sales Comparison
-- Demonstrates: Yearly aggregation and annual growth rate comparison
-- Note: Olist has partial data for 2016 (started Sept), full data for 2017, and up to Oct 2018.
-- ============================================================
WITH yearly_sales AS (
    SELECT 
        YEAR(o.order_purchase_timestamp) AS order_year,
        COUNT(DISTINCT o.order_id)       AS total_orders,
        COUNT(DISTINCT c.customer_unique_id) AS total_customers,
        ROUND(SUM(oi.price), 2)          AS annual_revenue
    FROM orders o
    INNER JOIN customers c ON o.customer_id = c.customer_id
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY YEAR(o.order_purchase_timestamp)
)
SELECT 
    order_year,
    total_orders,
    total_customers,
    annual_revenue,
    LAG(annual_revenue, 1) OVER (ORDER BY order_year) AS prior_year_revenue,
    ROUND(
        (annual_revenue - LAG(annual_revenue, 1) OVER (ORDER BY order_year))
        / NULLIF(LAG(annual_revenue, 1) OVER (ORDER BY order_year), 0) * 100,
        2
    ) AS yoy_growth_pct
FROM yearly_sales
ORDER BY order_year;


-- ============================================================
-- 4. Month-over-Month Growth Analysis with Trend Indicator
-- Demonstrates: CASE statements and threshold segmentation
-- ============================================================
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS year_month,
        ROUND(SUM(oi.price), 2) AS revenue
    FROM orders o
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
),
revenue_lagged AS (
    SELECT 
        year_month,
        revenue,
        LAG(revenue) OVER (ORDER BY year_month) AS prior_revenue
    FROM monthly_sales
)
SELECT 
    year_month,
    revenue,
    prior_revenue,
    ROUND(revenue - prior_revenue, 2) AS absolute_change,
    ROUND((revenue - prior_revenue) / NULLIF(prior_revenue, 0) * 100, 2) AS growth_pct,
    CASE 
        WHEN prior_revenue IS NULL THEN 'Baseline'
        WHEN revenue > prior_revenue * 1.10 THEN '▲ Significant Growth (>10%)'
        WHEN revenue > prior_revenue THEN '▲ Moderate Growth'
        WHEN revenue < prior_revenue * 0.90 THEN '▼ Significant Decline (>10%)'
        ELSE '▼ Moderate Decline'
    END AS trajectory
FROM revenue_lagged
ORDER BY year_month;


-- ============================================================
-- 5. Daily Order Volume & 7-Day Moving Average
-- Demonstrates: Window frames (ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
-- ============================================================
WITH daily_orders AS (
    SELECT 
        DATE(o.order_purchase_timestamp) AS order_date,
        COUNT(DISTINCT o.order_id)       AS daily_orders,
        ROUND(SUM(oi.price), 2)          AS daily_revenue
    FROM orders o
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY DATE(o.order_purchase_timestamp)
)
SELECT 
    order_date,
    daily_orders,
    daily_revenue,
    ROUND(
        AVG(daily_orders) OVER (
            ORDER BY order_date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ), 2
    ) AS rolling_7d_avg_orders,
    ROUND(
        AVG(daily_revenue) OVER (
            ORDER BY order_date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ), 2
    ) AS rolling_7d_avg_revenue
FROM daily_orders
ORDER BY order_date DESC
LIMIT 60;


-- ============================================================
-- 6. Revenue and Volume by Payment Method
-- Demonstrates: Avoiding fan-out duplication by pre-aggregating payments per order
-- ============================================================
WITH delivered_order_ids AS (
    SELECT order_id 
    FROM orders 
    WHERE order_status = 'delivered'
)
SELECT 
    op.payment_type,
    COUNT(DISTINCT op.order_id)                                  AS orders_count,
    ROUND(SUM(op.payment_value), 2)                              AS total_payment_value,
    ROUND(AVG(op.payment_value), 2)                              AS avg_payment_value,
    ROUND(AVG(op.payment_installments), 1)                       AS avg_installments,
    ROUND(
        SUM(op.payment_value) / SUM(SUM(op.payment_value)) OVER () * 100, 
        2
    )                                                            AS payment_share_pct
FROM order_payments op
INNER JOIN delivered_order_ids doi ON op.order_id = doi.order_id
GROUP BY op.payment_type
ORDER BY total_payment_value DESC;


-- ============================================================
-- 7. Average Order Value (AOV) Distribution by Month
-- Demonstrates: Multi-tiered aggregation (Order-level sum to Monthly statistics)
-- ============================================================
WITH order_totals AS (
    SELECT 
        o.order_id,
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS year_month,
        SUM(oi.price) AS order_total
    FROM orders o
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.order_id, DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
)
SELECT 
    year_month,
    COUNT(order_id)           AS total_orders,
    ROUND(AVG(order_total), 2) AS aov,
    ROUND(MIN(order_total), 2) AS min_order_val,
    ROUND(MAX(order_total), 2) AS max_order_val
FROM order_totals
GROUP BY year_month
ORDER BY year_month;

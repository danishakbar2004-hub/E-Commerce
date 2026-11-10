-- ============================================================
-- E-Commerce Analytics Platform
-- Module: Advanced SQL Demonstrations
-- Script: sql/06_advanced_sql.sql
-- Dataset: Brazilian E-Commerce Public Dataset by Olist
-- Description: Explicit showcase of Window Functions, CTE Chains,
--              Self-Joins, Subqueries, Cohort Retention, and Date Math
-- ============================================================

USE ecommerce_analytics;

-- ============================================================
-- 1. WINDOW FUNCTIONS SHOWCASE:
-- Demonstrates: RANK(), DENSE_RANK(), and ROW_NUMBER() side-by-side
-- Explaining tie-breaking and rank continuity across top categories
-- ============================================================
WITH category_revenue AS (
    SELECT 
        COALESCE(pct.product_category_name_english, p.product_category_name, 'Uncategorized') AS category_english,
        ROUND(SUM(oi.price), 2) AS total_revenue
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    INNER JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN product_category_translation pct ON p.product_category_name = pct.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY category_english
)
SELECT 
    category_english,
    total_revenue,
    ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS row_num,
    RANK()       OVER (ORDER BY total_revenue DESC) AS standard_rank,
    DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS dense_rank
FROM category_revenue
ORDER BY total_revenue DESC
LIMIT 15;


-- ============================================================
-- 2. WINDOW FRAMES & MOVING AVERAGES:
-- Demonstrates: ROWS BETWEEN 2 PRECEDING AND CURRENT ROW (Rolling 3-Month)
--               and Unbounded Preceding (Running Total)
-- ============================================================
WITH monthly_revenue AS (
    SELECT 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS ym,
        ROUND(SUM(oi.price), 2) AS monthly_sales
    FROM orders o
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
)
SELECT 
    ym,
    monthly_sales,
    -- Running Cumulative Total
    SUM(monthly_sales) OVER (
        ORDER BY ym 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_cumulative_sales,
    -- 3-Month Rolling Average
    ROUND(
        AVG(monthly_sales) OVER (
            ORDER BY ym 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    ) AS rolling_3m_average,
    -- Prior Year Benchmark via LAG(12)
    LAG(monthly_sales, 12) OVER (ORDER BY ym) AS sales_same_month_last_year
FROM monthly_revenue
ORDER BY ym ASC;


-- ============================================================
-- 3. SELF-JOIN DEMONSTRATION:
-- Month-over-Month comparison using relational Self-Join (alternative to LAG)
-- Demonstrates: Aliased self-referential joins with interval date matching
-- ============================================================
WITH monthly_summary AS (
    SELECT 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01') AS month_start,
        ROUND(SUM(oi.price), 2) AS revenue
    FROM orders o
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01')
)
SELECT 
    cur.month_start                                                AS current_month,
    cur.revenue                                                    AS current_revenue,
    prev.month_start                                               AS previous_month,
    prev.revenue                                                   AS prior_revenue,
    ROUND(cur.revenue - prev.revenue, 2)                           AS absolute_diff,
    ROUND((cur.revenue - prev.revenue) / prev.revenue * 100, 2)    AS mom_growth_pct
FROM monthly_summary cur
LEFT JOIN monthly_summary prev 
    ON cur.month_start = DATE_ADD(prev.month_start, INTERVAL 1 MONTH)
ORDER BY cur.month_start ASC;


-- ============================================================
-- 4. COHORT RETENTION ANALYSIS (Multi-Tiered CTE Chain):
-- Tracks monthly cohorts over 6 months post-initial acquisition
-- ============================================================
WITH customer_first_order AS (
    SELECT 
        c.customer_unique_id,
        DATE_FORMAT(MIN(o.order_purchase_timestamp), '%Y-%m') AS cohort_month,
        MIN(o.order_purchase_timestamp) AS first_order_date
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
customer_activities AS (
    SELECT 
        cfo.cohort_month,
        cfo.customer_unique_id,
        -- Cross-database compatible month difference calculation (MySQL, PostgreSQL, DuckDB, ANSI)
        (YEAR(o.order_purchase_timestamp) - YEAR(cfo.first_order_date)) * 12 +
        (MONTH(o.order_purchase_timestamp) - MONTH(cfo.first_order_date)) AS month_number
    FROM orders o
    INNER JOIN customers c ON o.customer_id = c.customer_id
    INNER JOIN customer_first_order cfo ON c.customer_unique_id = cfo.customer_unique_id
    WHERE o.order_status = 'delivered'
),
cohort_sizes AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT customer_unique_id) AS cohort_size
    FROM customer_first_order
    GROUP BY cohort_month
)
SELECT 
    ca.cohort_month,
    cs.cohort_size,
    ca.month_number,
    COUNT(DISTINCT ca.customer_unique_id) AS active_retained_customers,
    ROUND(
        COUNT(DISTINCT ca.customer_unique_id) / cs.cohort_size * 100, 
        2
    ) AS retention_rate_pct
FROM customer_activities ca
INNER JOIN cohort_sizes cs ON ca.cohort_month = cs.cohort_month
WHERE ca.month_number BETWEEN 0 AND 6
GROUP BY ca.cohort_month, cs.cohort_size, ca.month_number
ORDER BY ca.cohort_month ASC, ca.month_number ASC;


-- ============================================================
-- 5. CORRELATED SUBQUERY VS INNER JOIN BENCHMARK:
-- Finds customers spending above the average customer spend
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
)
SELECT 
    cs.customer_unique_id,
    cs.total_spend,
    ROUND((SELECT AVG(total_spend) FROM customer_spend), 2) AS benchmark_avg_spend,
    ROUND(cs.total_spend - (SELECT AVG(total_spend) FROM customer_spend), 2) AS delta_above_avg
FROM customer_spend cs
WHERE cs.total_spend > (SELECT AVG(total_spend) FROM customer_spend)
ORDER BY cs.total_spend DESC
LIMIT 20;


-- ============================================================
-- 6. DATE MATHEMATICS & TEMPORAL FUNCTIONS SUITE:
-- Demonstrates: DAYNAME, TIMESTAMPDIFF, DATEDIFF, QUARTER, EXTRACT
-- ============================================================
SELECT 
    o.order_id,
    o.order_purchase_timestamp,
    DAYNAME(o.order_purchase_timestamp)   AS purchase_day_of_week,
    QUARTER(o.order_purchase_timestamp)   AS calendar_quarter,
    TIMESTAMPDIFF(HOUR, o.order_purchase_timestamp, o.order_approved_at) AS hours_to_payment_approval,
    DATEDIFF(o.order_delivered_carrier_date, o.order_purchase_timestamp) AS days_to_carrier_dispatch,
    DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) AS total_delivery_days,
    DATEDIFF(o.order_estimated_delivery_date, o.order_delivered_customer_date) AS delivery_buffer_days
FROM orders o
WHERE o.order_status = 'delivered' 
  AND o.order_delivered_customer_date IS NOT NULL
ORDER BY o.order_purchase_timestamp DESC
LIMIT 15;

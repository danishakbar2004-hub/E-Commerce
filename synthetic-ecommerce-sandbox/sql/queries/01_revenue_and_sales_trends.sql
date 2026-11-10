-- ============================================================
-- SQL ANALYTICS QUERIES
-- File: 01_revenue_and_sales_trends.sql
-- ============================================================

-- ============================================================
-- Q1: TOTAL REVENUE (all-time, Delivered orders only)
-- Concepts: JOINs, aggregation, CASE
-- ============================================================
SELECT
    COUNT(DISTINCT o.order_id)                                      AS total_orders,
    COUNT(DISTINCT o.customer_id)                                   AS unique_customers,
    SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) AS gross_revenue,
    SUM(o.discount_amount)                                          AS total_order_discounts,
    SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100))
        - SUM(o.discount_amount)                                    AS net_revenue,
    SUM(o.shipping_fee)                                             AS total_shipping_revenue,
    AVG(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) AS avg_item_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Delivered';


-- ============================================================
-- Q2: MONTHLY SALES TRENDS
-- Concepts: DATE functions, GROUP BY, window functions
-- ============================================================
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS sales_month,   -- MySQL
        -- TO_CHAR(o.order_date, 'YYYY-MM') AS sales_month,  -- PostgreSQL
        COUNT(DISTINCT o.order_id)         AS orders_count,
        COUNT(DISTINCT o.customer_id)      AS unique_customers,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100))
                                           AS gross_revenue,
        SUM(o.discount_amount)             AS discount_given,
        SUM(o.shipping_fee)                AS shipping_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
    -- GROUP BY TO_CHAR(o.order_date, 'YYYY-MM')  -- PostgreSQL
)
SELECT
    sales_month,
    orders_count,
    unique_customers,
    ROUND(gross_revenue, 2)              AS gross_revenue,
    ROUND(discount_given, 2)             AS discount_given,
    ROUND(gross_revenue - discount_given, 2) AS net_revenue,
    -- Month-over-month revenue growth %
    ROUND(
        (gross_revenue - LAG(gross_revenue) OVER (ORDER BY sales_month))
        / NULLIF(LAG(gross_revenue) OVER (ORDER BY sales_month), 0) * 100,
        2
    )                                    AS mom_revenue_growth_pct,
    -- Running cumulative revenue
    ROUND(SUM(gross_revenue) OVER (ORDER BY sales_month
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2) AS cumulative_revenue
FROM monthly_sales
ORDER BY sales_month;


-- ============================================================
-- Q3: YEARLY REVENUE SUMMARY
-- Concepts: DATE functions, GROUP BY
-- ============================================================
SELECT
    YEAR(o.order_date)                                              AS sales_year,  -- MySQL
    -- EXTRACT(YEAR FROM o.order_date) AS sales_year,              -- PostgreSQL
    COUNT(DISTINCT o.order_id)                                      AS total_orders,
    SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) AS gross_revenue,
    ROUND(AVG(
        (SELECT SUM(oi2.quantity * oi2.unit_price * (1 - oi2.discount_pct / 100))
         FROM order_items oi2
         WHERE oi2.order_id = o.order_id)
    ), 2)                                                           AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Delivered'
GROUP BY YEAR(o.order_date)
ORDER BY sales_year;


-- ============================================================
-- Q4: MONTH-OVER-MONTH REVENUE GROWTH (standalone query)
-- Concepts: CTEs, LAG window function, CASE
-- ============================================================
WITH monthly_rev AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS yr_month,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
),
growth AS (
    SELECT
        yr_month,
        revenue,
        LAG(revenue) OVER (ORDER BY yr_month) AS prev_month_revenue
    FROM monthly_rev
)
SELECT
    yr_month,
    ROUND(revenue, 2)              AS revenue,
    ROUND(prev_month_revenue, 2)   AS prev_month_revenue,
    ROUND(revenue - prev_month_revenue, 2) AS revenue_change,
    ROUND(
        (revenue - prev_month_revenue) / NULLIF(prev_month_revenue, 0) * 100,
        2
    )                              AS growth_pct,
    CASE
        WHEN revenue > prev_month_revenue THEN '▲ Growth'
        WHEN revenue < prev_month_revenue THEN '▼ Decline'
        ELSE '→ Flat'
    END                            AS trend
FROM growth
ORDER BY yr_month;


-- ============================================================
-- Q5: QUARTERLY REVENUE BREAKDOWN
-- Concepts: CASE, GROUP BY, Date functions
-- ============================================================
SELECT
    YEAR(o.order_date)   AS sales_year,
    QUARTER(o.order_date) AS sales_quarter,            -- MySQL
    -- EXTRACT(QUARTER FROM o.order_date) AS quarter,  -- PostgreSQL
    CONCAT('Q', QUARTER(o.order_date), '-', YEAR(o.order_date)) AS period_label,
    COUNT(DISTINCT o.order_id)                          AS orders,
    COUNT(DISTINCT o.customer_id)                       AS customers,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)), 2) AS gross_revenue,
    ROUND(AVG(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)), 2) AS avg_item_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Delivered'
GROUP BY YEAR(o.order_date), QUARTER(o.order_date)
ORDER BY sales_year, sales_quarter;


-- ============================================================
-- Q6: AVERAGE ORDER VALUE (AOV) — Monthly
-- Concepts: Subquery, CTEs, aggregation
-- ============================================================
WITH order_totals AS (
    SELECT
        o.order_id,
        DATE_FORMAT(o.order_date, '%Y-%m') AS yr_month,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) - o.discount_amount
            AS order_net_value
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY o.order_id, DATE_FORMAT(o.order_date, '%Y-%m'), o.discount_amount
)
SELECT
    yr_month,
    COUNT(order_id)              AS total_orders,
    ROUND(SUM(order_net_value), 2)  AS total_net_revenue,
    ROUND(AVG(order_net_value), 2)  AS avg_order_value,
    ROUND(MIN(order_net_value), 2)  AS min_order_value,
    ROUND(MAX(order_net_value), 2)  AS max_order_value
FROM order_totals
GROUP BY yr_month
ORDER BY yr_month;

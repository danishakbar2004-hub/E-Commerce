-- ============================================================
-- SQL ANALYTICS QUERIES
-- File: 05_regional_analysis.sql
-- ============================================================

-- ============================================================
-- Q1: REVENUE BY REGION
-- Concepts: JOINs, GROUP BY, window functions
-- ============================================================
SELECT
    r.region_id,
    r.region_name,
    r.country,
    COUNT(DISTINCT o.order_id)                                        AS total_orders,
    COUNT(DISTINCT o.customer_id)                                     AS unique_customers,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)), 2)
                                                                      AS gross_revenue,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100))
        - SUM(o.discount_amount), 2)                                  AS net_revenue,
    ROUND(AVG(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)), 2)
                                                                      AS avg_order_value,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100))
        / SUM(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)))
            OVER () * 100, 2)                                         AS revenue_share_pct,
    RANK() OVER (ORDER BY SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) DESC)
                                                                      AS revenue_rank
FROM regions r
JOIN orders o      ON r.region_id  = o.region_id
JOIN order_items oi ON o.order_id  = oi.order_id
WHERE o.status = 'Delivered'
GROUP BY r.region_id, r.region_name, r.country
ORDER BY gross_revenue DESC;


-- ============================================================
-- Q2: REGIONAL MONTHLY TRENDS
-- Concepts: CTEs, DATE functions, window functions
-- ============================================================
WITH region_monthly AS (
    SELECT
        r.region_name,
        r.country,
        DATE_FORMAT(o.order_date, '%Y-%m') AS yr_month,
        COUNT(DISTINCT o.order_id)         AS orders,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)), 2) AS revenue
    FROM regions r
    JOIN orders o      ON r.region_id  = o.region_id
    JOIN order_items oi ON o.order_id  = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY r.region_name, r.country, DATE_FORMAT(o.order_date, '%Y-%m')
)
SELECT
    region_name,
    country,
    yr_month,
    orders,
    revenue,
    -- Region-specific MoM growth
    ROUND(
        (revenue - LAG(revenue) OVER (PARTITION BY region_name ORDER BY yr_month))
        / NULLIF(LAG(revenue) OVER (PARTITION BY region_name ORDER BY yr_month), 0) * 100,
        2
    ) AS mom_growth_pct
FROM region_monthly
ORDER BY region_name, yr_month;


-- ============================================================
-- Q3: COUNTRY-LEVEL REVENUE SUMMARY
-- Concepts: GROUP BY, aggregation, HAVING
-- ============================================================
SELECT
    r.country,
    COUNT(DISTINCT r.region_id)                                      AS regions_count,
    COUNT(DISTINCT c.customer_id)                                    AS total_customers,
    COUNT(DISTINCT o.order_id)                                       AS total_orders,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)), 2) AS gross_revenue,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100))
        / COUNT(DISTINCT o.order_id), 2)                             AS aov
FROM regions r
JOIN customers c ON r.region_id  = c.region_id
JOIN orders o   ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Delivered'
GROUP BY r.country
HAVING gross_revenue > 0
ORDER BY gross_revenue DESC;


-- ============================================================
-- Q4: BEST-SELLING CATEGORIES PER REGION
-- Concepts: Subqueries, window functions, RANK
-- ============================================================
WITH region_category AS (
    SELECT
        r.region_name,
        c.category_name,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) AS revenue
    FROM regions r
    JOIN orders     o  ON r.region_id   = o.region_id
    JOIN order_items oi ON o.order_id   = oi.order_id
    JOIN products   p  ON oi.product_id = p.product_id
    JOIN categories c  ON p.category_id = c.category_id
    WHERE o.status = 'Delivered'
    GROUP BY r.region_name, c.category_name
),
ranked AS (
    SELECT
        region_name,
        category_name,
        ROUND(revenue, 2) AS revenue,
        RANK() OVER (PARTITION BY region_name ORDER BY revenue DESC) AS cat_rank
    FROM region_category
)
SELECT *
FROM ranked
WHERE cat_rank <= 3
ORDER BY region_name, cat_rank;


-- ============================================================
-- Q5: SHIPPING PERFORMANCE BY REGION
-- Concepts: DATE functions, CASE, aggregation
-- ============================================================
SELECT
    r.region_name,
    COUNT(o.order_id)  AS total_orders,
    COUNT(CASE WHEN o.status = 'Delivered' THEN 1 END)  AS delivered,
    COUNT(CASE WHEN o.status = 'Cancelled' THEN 1 END)  AS cancelled,
    COUNT(CASE WHEN o.status IN ('Shipped','Processing') THEN 1 END) AS in_transit,
    ROUND(COUNT(CASE WHEN o.status = 'Cancelled' THEN 1 END)
        / COUNT(o.order_id) * 100, 2)                   AS cancellation_rate_pct,
    ROUND(AVG(DATEDIFF(o.ship_date, o.order_date)), 1)  AS avg_days_to_ship  -- MySQL
    -- ROUND(AVG(DATE_PART('day', o.ship_date - o.order_date)), 1) -- PostgreSQL
FROM regions r
LEFT JOIN orders o ON r.region_id = o.region_id
GROUP BY r.region_name
ORDER BY total_orders DESC;

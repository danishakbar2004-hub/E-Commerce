-- ============================================================
-- SQL ANALYTICS QUERIES
-- File: 02_product_performance.sql
-- ============================================================

-- ============================================================
-- Q1: TOP 10 PRODUCTS BY REVENUE
-- Concepts: JOINs, GROUP BY, ORDER BY, LIMIT
-- ============================================================
SELECT
    p.product_id,
    p.product_name,
    c.category_name,
    COUNT(DISTINCT oi.order_id)                                      AS orders_count,
    SUM(oi.quantity)                                                 AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)), 2)
                                                                     AS gross_revenue,
    ROUND(SUM(oi.quantity * (oi.unit_price - p.cost_price) * (1 - oi.discount_pct / 100)), 2)
                                                                     AS gross_profit,
    ROUND(
        SUM(oi.quantity * (oi.unit_price - p.cost_price) * (1 - oi.discount_pct / 100))
        / NULLIF(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)), 0) * 100,
        2
    )                                                                AS profit_margin_pct
FROM order_items oi
JOIN orders     o  ON oi.order_id  = o.order_id
JOIN products   p  ON oi.product_id = p.product_id
JOIN categories c  ON p.category_id = c.category_id
WHERE o.status = 'Delivered'
GROUP BY p.product_id, p.product_name, c.category_name
ORDER BY gross_revenue DESC
LIMIT 10;


-- ============================================================
-- Q2: BEST-PERFORMING PRODUCT CATEGORIES
-- Concepts: JOINs, GROUP BY, HAVING, subqueries
-- ============================================================
WITH category_revenue AS (
    SELECT
        c.category_id,
        c.category_name,
        c.parent_id,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) AS revenue,
        SUM(oi.quantity * (oi.unit_price - p.cost_price) * (1 - oi.discount_pct / 100)) AS profit,
        SUM(oi.quantity)   AS units_sold,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM order_items oi
    JOIN orders     o  ON oi.order_id   = o.order_id
    JOIN products   p  ON oi.product_id = p.product_id
    JOIN categories c  ON p.category_id = c.category_id
    WHERE o.status = 'Delivered'
    GROUP BY c.category_id, c.category_name, c.parent_id
)
SELECT
    cr.category_name,
    COALESCE(parent.category_name, 'Top Level') AS parent_category,
    cr.order_count,
    cr.units_sold,
    ROUND(cr.revenue, 2)  AS gross_revenue,
    ROUND(cr.profit, 2)   AS gross_profit,
    ROUND(cr.profit / NULLIF(cr.revenue, 0) * 100, 2) AS margin_pct,
    ROUND(cr.revenue / SUM(cr.revenue) OVER () * 100, 2) AS revenue_share_pct,
    RANK() OVER (ORDER BY cr.revenue DESC) AS revenue_rank
FROM category_revenue cr
LEFT JOIN categories parent ON cr.parent_id = parent.category_id
ORDER BY cr.revenue DESC;


-- ============================================================
-- Q3: PRODUCT PERFORMANCE WITH RANKING
-- Concepts: Window functions (RANK, DENSE_RANK, NTILE), CTEs
-- ============================================================
WITH product_metrics AS (
    SELECT
        p.product_id,
        p.product_name,
        c.category_name,
        SUM(oi.quantity)  AS units_sold,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)), 2) AS revenue,
        ROUND(SUM(oi.quantity * (oi.unit_price - p.cost_price) * (1 - oi.discount_pct / 100)), 2) AS profit
    FROM order_items oi
    JOIN orders   o ON oi.order_id  = o.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN categories c ON p.category_id = c.category_id
    WHERE o.status = 'Delivered'
    GROUP BY p.product_id, p.product_name, c.category_name
)
SELECT
    product_name,
    category_name,
    units_sold,
    revenue,
    profit,
    ROUND(profit / NULLIF(revenue, 0) * 100, 2) AS margin_pct,
    RANK()       OVER (ORDER BY revenue  DESC) AS revenue_rank,
    RANK()       OVER (ORDER BY profit   DESC) AS profit_rank,
    RANK()       OVER (ORDER BY units_sold DESC) AS volume_rank,
    NTILE(4)     OVER (ORDER BY revenue  DESC) AS revenue_quartile, -- 1=top, 4=bottom
    -- Category rank
    RANK()       OVER (PARTITION BY category_name ORDER BY revenue DESC) AS category_rank
FROM product_metrics
ORDER BY revenue DESC;


-- ============================================================
-- Q4: SLOW-MOVING vs FAST-MOVING PRODUCTS
-- Concepts: CASE, subqueries, HAVING
-- ============================================================
WITH product_sales AS (
    SELECT
        p.product_id,
        p.product_name,
        p.stock_qty,
        COALESCE(SUM(oi.quantity), 0) AS total_sold
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    LEFT JOIN orders o ON oi.order_id = o.order_id AND o.status = 'Delivered'
    WHERE p.is_active = TRUE
    GROUP BY p.product_id, p.product_name, p.stock_qty
)
SELECT
    product_id,
    product_name,
    stock_qty,
    total_sold,
    CASE
        WHEN total_sold >= 100 THEN 'High Velocity'
        WHEN total_sold >= 30  THEN 'Medium Velocity'
        WHEN total_sold >= 10  THEN 'Low Velocity'
        ELSE 'Slow Moving'
    END AS velocity_segment,
    CASE
        WHEN total_sold = 0 THEN 'Dead Stock'
        WHEN stock_qty = 0  THEN 'Out of Stock'
        WHEN stock_qty < 20 THEN 'Low Stock'
        ELSE 'Adequate Stock'
    END AS stock_status
FROM product_sales
ORDER BY total_sold DESC;


-- ============================================================
-- Q5: MONTHLY PRODUCT TREND (which products drive each month)
-- Concepts: CTEs, window functions, DATE functions
-- ============================================================
WITH monthly_product AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS yr_month,
        p.product_name,
        c.category_name,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) AS revenue
    FROM order_items oi
    JOIN orders   o ON oi.order_id   = o.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN categories c ON p.category_id = c.category_id
    WHERE o.status = 'Delivered'
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m'), p.product_name, c.category_name
)
SELECT
    yr_month,
    product_name,
    category_name,
    ROUND(revenue, 2) AS revenue,
    RANK() OVER (PARTITION BY yr_month ORDER BY revenue DESC) AS rank_in_month
FROM monthly_product
QUALIFY rank_in_month <= 5   -- Top 5 per month (use subquery in MySQL < 8.0.2)
ORDER BY yr_month, rank_in_month;

-- ============================================================
-- MySQL-compatible version of Q5 (without QUALIFY)
-- ============================================================
SELECT *
FROM (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS yr_month,
        p.product_name,
        c.category_name,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)), 2) AS revenue,
        RANK() OVER (
            PARTITION BY DATE_FORMAT(o.order_date, '%Y-%m')
            ORDER BY SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) DESC
        ) AS rank_in_month
    FROM order_items oi
    JOIN orders   o ON oi.order_id   = o.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN categories c ON p.category_id = c.category_id
    WHERE o.status = 'Delivered'
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m'), p.product_id, p.product_name, c.category_name
) ranked
WHERE rank_in_month <= 5
ORDER BY yr_month, rank_in_month;

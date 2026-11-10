-- ============================================================
-- E-Commerce Analytics Platform
-- Module: Product Performance Analysis
-- Script: sql/02_product_analysis.sql
-- Dataset: Brazilian E-Commerce Public Dataset by Olist
-- ============================================================

USE ecommerce_analytics;

-- ============================================================
-- 1. Top 10 Products by Revenue
-- Demonstrates: Multi-table joins, category translation fallback, Window RANK()
-- ============================================================
WITH product_sales AS (
    SELECT 
        p.product_id,
        COALESCE(pct.product_category_name_english, p.product_category_name, 'Uncategorized') AS category_name,
        COUNT(oi.order_item_id) AS units_sold,
        COUNT(DISTINCT oi.order_id) AS orders_count,
        ROUND(SUM(oi.price), 2) AS total_revenue,
        ROUND(AVG(oi.price), 2) AS avg_unit_price
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    INNER JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN product_category_translation pct ON p.product_category_name = pct.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY p.product_id, category_name
)
SELECT 
    product_id,
    category_name,
    units_sold,
    orders_count,
    total_revenue,
    avg_unit_price,
    DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM product_sales
ORDER BY total_revenue DESC
LIMIT 10;


-- ============================================================
-- 2. Top 10 Products by Quantity Sold (Sales Volume)
-- ============================================================
SELECT 
    p.product_id,
    COALESCE(pct.product_category_name_english, p.product_category_name, 'Uncategorized') AS category_name,
    COUNT(oi.order_item_id) AS units_sold,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(oi.price), 2) AS avg_unit_price,
    DENSE_RANK() OVER (ORDER BY COUNT(oi.order_item_id) DESC) AS volume_rank
FROM order_items oi
INNER JOIN orders o ON oi.order_id = o.order_id
INNER JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_translation pct ON p.product_category_name = pct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY p.product_id, category_name
ORDER BY units_sold DESC
LIMIT 10;


-- ============================================================
-- 3. Best-Performing Product Categories by Revenue
-- Demonstrates: Category translation, revenue share using Window function
-- ============================================================
WITH category_metrics AS (
    SELECT 
        COALESCE(pct.product_category_name_english, p.product_category_name, 'Uncategorized') AS category_english,
        COUNT(DISTINCT p.product_id) AS distinct_products_offered,
        COUNT(oi.order_item_id)      AS units_sold,
        COUNT(DISTINCT oi.order_id)  AS orders_count,
        ROUND(SUM(oi.price), 2)      AS total_revenue,
        ROUND(AVG(oi.price), 2)      AS avg_unit_price
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    INNER JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN product_category_translation pct ON p.product_category_name = pct.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY category_english
)
SELECT 
    category_english,
    distinct_products_offered,
    units_sold,
    orders_count,
    total_revenue,
    avg_unit_price,
    ROUND(total_revenue / SUM(total_revenue) OVER () * 100, 2) AS revenue_share_pct,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM category_metrics
ORDER BY total_revenue DESC
LIMIT 15;


-- ============================================================
-- 4. Lowest-Performing Categories (Bottom 10 by Revenue)
-- Useful for catalog rationalization and inventory pruning decisions
-- ============================================================
SELECT 
    COALESCE(pct.product_category_name_english, p.product_category_name, 'Uncategorized') AS category_english,
    COUNT(DISTINCT p.product_id) AS product_count,
    COUNT(oi.order_item_id)      AS units_sold,
    ROUND(SUM(oi.price), 2)      AS total_revenue,
    ROUND(AVG(oi.price), 2)      AS avg_unit_price
FROM order_items oi
INNER JOIN orders o ON oi.order_id = o.order_id
INNER JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_translation pct ON p.product_category_name = pct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category_english
ORDER BY total_revenue ASC
LIMIT 10;


-- ============================================================
-- 5. Average, Min, and Max Product Price by Category
-- Demonstrates: Statistical range aggregation and HAVING filters
-- ============================================================
SELECT 
    COALESCE(pct.product_category_name_english, p.product_category_name, 'Uncategorized') AS category_english,
    COUNT(DISTINCT p.product_id) AS product_count,
    ROUND(AVG(oi.price), 2)      AS avg_price,
    ROUND(MIN(oi.price), 2)      AS min_price,
    ROUND(MAX(oi.price), 2)      AS max_price,
    ROUND(STDDEV(oi.price), 2)   AS price_std_dev
FROM order_items oi
INNER JOIN orders o ON oi.order_id = o.order_id
INNER JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_translation pct ON p.product_category_name = pct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category_english
HAVING COUNT(oi.order_item_id) >= 50
ORDER BY avg_price DESC;


-- ============================================================
-- 6. Product Revenue Contribution Percentage (Pareto Principle / 80-20 Rule)
-- Demonstrates: Running total percentage across ranked products
-- ============================================================
WITH product_totals AS (
    SELECT 
        p.product_id,
        COALESCE(pct.product_category_name_english, 'Uncategorized') AS category_english,
        SUM(oi.price) AS revenue
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    INNER JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN product_category_translation pct ON p.product_category_name = pct.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY p.product_id, category_english
),
running_revenue AS (
    SELECT 
        product_id,
        category_english,
        ROUND(revenue, 2) AS revenue,
        ROUND(revenue / SUM(revenue) OVER () * 100, 4) AS individual_pct,
        ROUND(
            SUM(revenue) OVER (
                ORDER BY revenue DESC 
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) / SUM(revenue) OVER () * 100, 
            2
        ) AS cumulative_revenue_pct,
        ROW_NUMBER() OVER (ORDER BY revenue DESC) AS product_rank
    FROM product_totals
)
SELECT 
    product_rank,
    product_id,
    category_english,
    revenue,
    individual_pct,
    cumulative_revenue_pct
FROM running_revenue
WHERE product_rank <= 25 OR cumulative_revenue_pct >= 79.9
ORDER BY product_rank ASC
LIMIT 30;


-- ============================================================
-- 7. Category Review Score vs Revenue Performance
-- Demonstrates: Joining review dimensions to evaluate quality perception
-- ============================================================
WITH latest_reviews AS (
    SELECT 
        order_id,
        review_score,
        ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_answer_timestamp DESC) AS rn
    FROM order_reviews
)
SELECT 
    COALESCE(pct.product_category_name_english, p.product_category_name, 'Uncategorized') AS category_english,
    ROUND(SUM(oi.price), 2)     AS total_revenue,
    COUNT(DISTINCT o.order_id)  AS total_orders,
    ROUND(AVG(lr.review_score), 2) AS avg_customer_rating,
    SUM(CASE WHEN lr.review_score >= 4 THEN 1 ELSE 0 END) AS positive_reviews,
    SUM(CASE WHEN lr.review_score <= 2 THEN 1 ELSE 0 END) AS negative_reviews
FROM order_items oi
INNER JOIN orders o ON oi.order_id = o.order_id
INNER JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_translation pct ON p.product_category_name = pct.product_category_name
LEFT JOIN latest_reviews lr ON o.order_id = lr.order_id AND lr.rn = 1
WHERE o.order_status = 'delivered'
GROUP BY category_english
HAVING total_orders >= 100
ORDER BY total_revenue DESC
LIMIT 15;

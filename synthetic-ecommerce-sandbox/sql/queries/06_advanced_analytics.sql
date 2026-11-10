-- ============================================================
-- SQL ANALYTICS QUERIES
-- File: 06_advanced_analytics.sql
-- Advanced concepts: Window functions, complex CTEs, etc.
-- ============================================================

-- ============================================================
-- Q1: RUNNING TOTALS & MOVING AVERAGES
-- Concepts: Window frames (ROWS BETWEEN), window functions
-- ============================================================
WITH monthly_rev AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS yr_month,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)), 2) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
)
SELECT
    yr_month,
    revenue,
    -- Cumulative (running) total
    SUM(revenue) OVER (
        ORDER BY yr_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                                AS cumulative_revenue,
    -- 3-month rolling average
    ROUND(AVG(revenue) OVER (
        ORDER BY yr_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2)                                            AS rolling_3m_avg,
    -- 6-month rolling average
    ROUND(AVG(revenue) OVER (
        ORDER BY yr_month
        ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
    ), 2)                                            AS rolling_6m_avg,
    -- Year-over-year (same month, prior year)
    LAG(revenue, 12) OVER (ORDER BY yr_month)        AS same_month_prior_year,
    ROUND(
        (revenue - LAG(revenue, 12) OVER (ORDER BY yr_month))
        / NULLIF(LAG(revenue, 12) OVER (ORDER BY yr_month), 0) * 100,
        2
    )                                                AS yoy_growth_pct
FROM monthly_rev
ORDER BY yr_month;


-- ============================================================
-- Q2: BASKET ANALYSIS — What products are bought together?
-- Concepts: Self-JOIN, GROUP BY, HAVING
-- ============================================================
SELECT
    p1.product_name  AS product_a,
    p2.product_name  AS product_b,
    COUNT(*)         AS times_bought_together
FROM order_items oi1
JOIN order_items oi2 ON oi1.order_id   = oi2.order_id
                     AND oi1.product_id < oi2.product_id  -- avoid duplicates
JOIN products p1 ON oi1.product_id = p1.product_id
JOIN products p2 ON oi2.product_id = p2.product_id
JOIN orders o    ON oi1.order_id   = o.order_id
WHERE o.status = 'Delivered'
GROUP BY p1.product_name, p2.product_name
HAVING COUNT(*) >= 2
ORDER BY times_bought_together DESC
LIMIT 20;


-- ============================================================
-- Q3: CUSTOMER ACQUISITION ANALYSIS
-- How fast are we acquiring new customers?
-- Concepts: CTEs, DATE functions, window functions
-- ============================================================
WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order_date
    FROM orders
    WHERE status = 'Delivered'
    GROUP BY customer_id
),
monthly_new_customers AS (
    SELECT
        DATE_FORMAT(first_order_date, '%Y-%m') AS yr_month,
        COUNT(*) AS new_customers
    FROM first_purchase
    GROUP BY DATE_FORMAT(first_order_date, '%Y-%m')
)
SELECT
    yr_month,
    new_customers,
    SUM(new_customers) OVER (ORDER BY yr_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_customers,
    ROUND(AVG(new_customers) OVER (ORDER BY yr_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 1)     AS rolling_3m_avg_new,
    ROUND(
        (new_customers - LAG(new_customers) OVER (ORDER BY yr_month))
        / NULLIF(LAG(new_customers) OVER (ORDER BY yr_month), 0) * 100,
        2
    )                                                       AS mom_growth_pct
FROM monthly_new_customers
ORDER BY yr_month;


-- ============================================================
-- Q4: ORDER STATUS FUNNEL
-- Concepts: CASE, GROUP BY, aggregation
-- ============================================================
SELECT
    status,
    COUNT(*)                                       AS order_count,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 2) AS pct_of_total,
    ROUND(SUM(
        (SELECT COALESCE(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)), 0)
         FROM order_items oi WHERE oi.order_id = o.order_id)
    ), 2)                                          AS associated_revenue
FROM orders o
GROUP BY status
ORDER BY FIELD(status, 'Delivered','Shipped','Processing','Pending','Refunded','Cancelled');


-- ============================================================
-- Q5: DISCOUNT IMPACT ANALYSIS
-- Do discounts increase order value or just reduce margin?
-- Concepts: CASE, GROUP BY, aggregation
-- ============================================================
WITH order_summary AS (
    SELECT
        o.order_id,
        o.discount_amount                                                      AS order_discount,
        SUM(oi.discount_pct)                                                   AS item_discount_sum,
        SUM(oi.quantity * oi.unit_price)                                       AS gross_value,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100))        AS net_item_value,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100))
            - o.discount_amount                                                AS final_order_value,
        COUNT(DISTINCT oi.product_id)                                          AS items_in_order
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY o.order_id, o.discount_amount
)
SELECT
    CASE
        WHEN order_discount = 0 AND item_discount_sum = 0 THEN 'No Discount'
        WHEN order_discount > 0 AND item_discount_sum = 0 THEN 'Order-Level Discount'
        WHEN order_discount = 0 AND item_discount_sum > 0 THEN 'Item-Level Discount'
        ELSE 'Both Discounts'
    END                             AS discount_type,
    COUNT(*)                        AS orders,
    ROUND(AVG(gross_value), 2)      AS avg_gross_order_value,
    ROUND(AVG(final_order_value),2) AS avg_net_order_value,
    ROUND(AVG(items_in_order), 1)   AS avg_items_per_order,
    ROUND(SUM(gross_value - final_order_value), 2) AS total_discount_given
FROM order_summary
GROUP BY discount_type
ORDER BY orders DESC;


-- ============================================================
-- Q6: REORDER PATTERNS — Time Between Purchases
-- Concepts: LAG window function, DATE differences, CTEs
-- ============================================================
WITH ordered_purchases AS (
    SELECT
        customer_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)
            AS prev_order_date
    FROM orders
    WHERE status = 'Delivered'
),
intervals AS (
    SELECT
        customer_id,
        DATEDIFF(order_date, prev_order_date) AS days_between_orders
    FROM ordered_purchases
    WHERE prev_order_date IS NOT NULL
)
SELECT
    CASE
        WHEN days_between_orders <= 30  THEN '0-30 days'
        WHEN days_between_orders <= 60  THEN '31-60 days'
        WHEN days_between_orders <= 90  THEN '61-90 days'
        WHEN days_between_orders <= 180 THEN '91-180 days'
        ELSE '180+ days'
    END                      AS reorder_interval,
    COUNT(*)                 AS frequency,
    ROUND(AVG(days_between_orders), 1) AS avg_days
FROM intervals
GROUP BY reorder_interval
ORDER BY avg_days;


-- ============================================================
-- Q7: PERCENT CONTRIBUTION — WINDOW FUNCTION SHOWCASE
-- Concepts: Multiple window functions in one query
-- ============================================================
WITH product_monthly AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m')  AS yr_month,
        c.category_name,
        p.product_name,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) AS revenue
    FROM order_items oi
    JOIN orders     o  ON oi.order_id   = o.order_id
    JOIN products   p  ON oi.product_id = p.product_id
    JOIN categories c  ON p.category_id = c.category_id
    WHERE o.status = 'Delivered'
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m'), c.category_name, p.product_name
)
SELECT
    yr_month,
    category_name,
    product_name,
    ROUND(revenue, 2) AS revenue,
    -- % of that month's total
    ROUND(revenue / SUM(revenue) OVER (PARTITION BY yr_month) * 100, 2)
                      AS pct_of_month,
    -- % of that category in that month
    ROUND(revenue / SUM(revenue) OVER (PARTITION BY yr_month, category_name) * 100, 2)
                      AS pct_of_category_in_month,
    -- Product rank within month
    RANK() OVER (PARTITION BY yr_month ORDER BY revenue DESC)
                      AS product_rank_in_month,
    -- Product rank within category and month
    RANK() OVER (PARTITION BY yr_month, category_name ORDER BY revenue DESC)
                      AS product_rank_in_category
FROM product_monthly
ORDER BY yr_month, revenue DESC;

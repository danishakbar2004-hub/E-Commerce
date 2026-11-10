-- ============================================================
-- SQL ANALYTICS QUERIES
-- File: 03_customer_analytics.sql
-- ============================================================

-- ============================================================
-- Q1: CUSTOMER PURCHASE FREQUENCY
-- Concepts: GROUP BY, HAVING, subqueries
-- ============================================================
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    r.region_name,
    COUNT(DISTINCT o.order_id)              AS total_orders,
    MIN(o.order_date)                       AS first_order_date,
    MAX(o.order_date)                       AS last_order_date,
    DATEDIFF(MAX(o.order_date), MIN(o.order_date)) AS days_as_customer,  -- MySQL
    -- DATE_PART('day', MAX(o.order_date) - MIN(o.order_date)) AS days_as_customer, -- PostgreSQL
    CASE
        WHEN COUNT(DISTINCT o.order_id) >= 10 THEN 'Very Frequent (10+)'
        WHEN COUNT(DISTINCT o.order_id) >= 5  THEN 'Frequent (5-9)'
        WHEN COUNT(DISTINCT o.order_id) >= 2  THEN 'Occasional (2-4)'
        ELSE 'One-time Buyer'
    END AS frequency_segment
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'Delivered'
GROUP BY c.customer_id, c.first_name, c.last_name, c.email, r.region_name
ORDER BY total_orders DESC;


-- ============================================================
-- Q2: REPEAT CUSTOMER RATE
-- Concepts: Subqueries, CASE, aggregation
-- ============================================================
WITH customer_order_counts AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS order_count
    FROM orders
    WHERE status = 'Delivered'
    GROUP BY customer_id
)
SELECT
    COUNT(*)                                           AS total_customers_who_ordered,
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END)  AS repeat_customers,
    SUM(CASE WHEN order_count = 1 THEN 1 ELSE 0 END)  AS one_time_customers,
    ROUND(
        SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END)
        / COUNT(*) * 100, 2
    )                                                  AS repeat_customer_rate_pct,
    ROUND(AVG(order_count), 2)                         AS avg_orders_per_customer,
    MAX(order_count)                                   AS max_orders_single_customer
FROM customer_order_counts;


-- ============================================================
-- Q3: CUSTOMER LIFETIME VALUE (CLV)
-- Concepts: JOINs, aggregation, window functions
-- ============================================================
WITH customer_revenue AS (
    SELECT
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.signup_date,
        r.region_name,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100))
            - SUM(o.discount_amount) AS lifetime_value,
        MIN(o.order_date)   AS first_purchase,
        MAX(o.order_date)   AS last_purchase
    FROM customers c
    JOIN orders o      ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id   = oi.order_id
    LEFT JOIN regions r ON c.region_id  = r.region_id
    WHERE o.status = 'Delivered'
    GROUP BY c.customer_id, c.first_name, c.last_name, c.signup_date, r.region_name
)
SELECT
    customer_id,
    customer_name,
    region_name,
    total_orders,
    ROUND(lifetime_value, 2)                            AS lifetime_value,
    ROUND(lifetime_value / total_orders, 2)             AS avg_order_value,
    DATEDIFF(last_purchase, first_purchase)             AS active_days,
    RANK() OVER (ORDER BY lifetime_value DESC)          AS clv_rank,
    NTILE(5) OVER (ORDER BY lifetime_value DESC)        AS clv_quintile  -- 1=top 20%
FROM customer_revenue
ORDER BY lifetime_value DESC;


-- ============================================================
-- Q4: NEW vs RETURNING CUSTOMERS PER MONTH
-- Concepts: Window functions, CTEs, DATE functions
-- ============================================================
WITH first_orders AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order_date
    FROM orders
    WHERE status = 'Delivered'
    GROUP BY customer_id
),
monthly_orders AS (
    SELECT
        o.customer_id,
        DATE_FORMAT(o.order_date, '%Y-%m') AS yr_month,
        fo.first_order_date
    FROM orders o
    JOIN first_orders fo ON o.customer_id = fo.customer_id
    WHERE o.status = 'Delivered'
)
SELECT
    yr_month,
    COUNT(DISTINCT customer_id) AS total_customers,
    COUNT(DISTINCT CASE
        WHEN DATE_FORMAT(first_order_date, '%Y-%m') = yr_month
        THEN customer_id END)   AS new_customers,
    COUNT(DISTINCT CASE
        WHEN DATE_FORMAT(first_order_date, '%Y-%m') != yr_month
        THEN customer_id END)   AS returning_customers,
    ROUND(COUNT(DISTINCT CASE
        WHEN DATE_FORMAT(first_order_date, '%Y-%m') != yr_month
        THEN customer_id END)
        / COUNT(DISTINCT customer_id) * 100, 1) AS returning_rate_pct
FROM monthly_orders
GROUP BY yr_month
ORDER BY yr_month;


-- ============================================================
-- Q5: CUSTOMER SEGMENTATION (Value-Based)
-- Concepts: CTEs, CASE, aggregation
-- ============================================================
WITH customer_metrics AS (
    SELECT
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name)   AS customer_name,
        COUNT(DISTINCT o.order_id)                AS order_count,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100))
            - SUM(o.discount_amount), 2)           AS total_spend,
        ROUND(AVG(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)), 2) AS avg_order_val
    FROM customers c
    JOIN orders o      ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id   = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT
    customer_id,
    customer_name,
    order_count,
    total_spend,
    avg_order_val,
    CASE
        WHEN total_spend >= 5000 AND order_count >= 5 THEN 'VIP Champion'
        WHEN total_spend >= 2000 AND order_count >= 3 THEN 'Loyal Customer'
        WHEN total_spend >= 500  AND order_count >= 2 THEN 'Potential Loyalist'
        WHEN order_count = 1     AND total_spend >= 1000 THEN 'High-Value New'
        WHEN order_count = 1                            THEN 'New Customer'
        ELSE 'At Risk'
    END AS customer_segment
FROM customer_metrics
ORDER BY total_spend DESC;


-- ============================================================
-- Q6: COHORT RETENTION ANALYSIS
-- Which signup-month cohorts retain best?
-- Concepts: CTEs, DATE functions, CASE, window functions
-- ============================================================
WITH cohorts AS (
    SELECT
        c.customer_id,
        DATE_FORMAT(c.signup_date, '%Y-%m')   AS cohort_month,
        DATE_FORMAT(o.order_date, '%Y-%m')    AS order_month,
        PERIOD_DIFF(
            DATE_FORMAT(o.order_date, '%Y%m'),
            DATE_FORMAT(c.signup_date, '%Y%m')
        )                                      AS months_since_signup
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status = 'Delivered'
),
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_size
    FROM cohorts
    WHERE months_since_signup = 0
    GROUP BY cohort_month
)
SELECT
    co.cohort_month,
    cs.cohort_size,
    co.months_since_signup AS month_number,
    COUNT(DISTINCT co.customer_id) AS active_customers,
    ROUND(COUNT(DISTINCT co.customer_id) / cs.cohort_size * 100, 1) AS retention_pct
FROM cohorts co
JOIN cohort_sizes cs ON co.cohort_month = cs.cohort_month
WHERE co.months_since_signup BETWEEN 0 AND 12
GROUP BY co.cohort_month, cs.cohort_size, co.months_since_signup
ORDER BY co.cohort_month, co.months_since_signup;

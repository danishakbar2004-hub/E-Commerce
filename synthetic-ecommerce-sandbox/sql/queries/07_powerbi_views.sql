-- ============================================================
-- POWER BI DATA EXPORT VIEWS
-- File: 07_powerbi_views.sql
-- Creates flattened views for direct import into Power BI
-- ============================================================

-- ============================================================
-- VIEW 1: fact_sales  (main fact table for Power BI)
-- ============================================================
CREATE OR REPLACE VIEW vw_fact_sales AS
SELECT
    oi.item_id,
    o.order_id,
    o.order_date,
    DATE_FORMAT(o.order_date, '%Y-%m-%d') AS order_date_key,
    YEAR(o.order_date)                    AS year,
    QUARTER(o.order_date)                 AS quarter,
    MONTH(o.order_date)                   AS month,
    MONTHNAME(o.order_date)               AS month_name,
    DAY(o.order_date)                     AS day,
    DAYNAME(o.order_date)                 AS day_name,
    o.status                              AS order_status,
    o.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.signup_date,
    p.product_id,
    p.product_name,
    cat.category_id,
    cat.category_name,
    r.region_id,
    r.region_name,
    r.country,
    c.city,
    oi.quantity,
    oi.unit_price,
    oi.discount_pct                       AS item_discount_pct,
    o.discount_amount                     AS order_discount_amount,
    o.shipping_fee,
    -- Calculated columns
    ROUND(oi.quantity * oi.unit_price, 2)                              AS gross_line_value,
    ROUND(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100), 2) AS net_line_value,
    ROUND(oi.quantity * (oi.unit_price - p.cost_price), 2)             AS gross_profit,
    ROUND(
        oi.quantity * (oi.unit_price - p.cost_price) * (1 - oi.discount_pct / 100)
        , 2
    )                                                                  AS net_profit
FROM order_items oi
JOIN orders     o   ON oi.order_id   = o.order_id
JOIN customers  c   ON o.customer_id = c.customer_id
JOIN products   p   ON oi.product_id = p.product_id
JOIN categories cat ON p.category_id = cat.category_id
LEFT JOIN regions r ON o.region_id   = r.region_id;


-- ============================================================
-- VIEW 2: dim_customers  (dimension for customer dashboard)
-- ============================================================
CREATE OR REPLACE VIEW vw_dim_customers AS
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    c.city,
    c.signup_date,
    r.region_name,
    r.country,
    -- Computed at view level
    COUNT(DISTINCT o.order_id)             AS total_orders,
    MIN(o.order_date)                      AS first_order_date,
    MAX(o.order_date)                      AS last_order_date,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100))
        - SUM(o.discount_amount), 2)       AS lifetime_value,
    DATEDIFF(CURDATE(), MAX(o.order_date)) AS days_since_last_order
FROM customers c
LEFT JOIN regions r     ON c.region_id  = r.region_id
LEFT JOIN orders o      ON c.customer_id = o.customer_id AND o.status = 'Delivered'
LEFT JOIN order_items oi ON o.order_id  = oi.order_id
GROUP BY c.customer_id, c.first_name, c.last_name,
         c.email, c.city, c.signup_date, r.region_name, r.country;


-- ============================================================
-- VIEW 3: dim_products  (dimension for product dashboard)
-- ============================================================
CREATE OR REPLACE VIEW vw_dim_products AS
SELECT
    p.product_id,
    p.product_name,
    p.unit_price,
    p.cost_price,
    ROUND(p.unit_price - p.cost_price, 2)                AS margin_per_unit,
    ROUND((p.unit_price - p.cost_price) / p.unit_price * 100, 2) AS margin_pct,
    p.stock_qty,
    p.launch_date,
    c.category_id,
    c.category_name,
    COALESCE(parent.category_name, c.category_name)      AS parent_category
FROM products p
JOIN categories c ON p.category_id = c.category_id
LEFT JOIN categories parent ON c.parent_id = parent.category_id;


-- ============================================================
-- VIEW 4: dim_date  (date dimension / calendar table)
-- ============================================================
-- Note: For Power BI, it's better to create a date dimension
-- in DAX using CALENDARAUTO(). This view is a SQL alternative.
CREATE OR REPLACE VIEW vw_dim_date AS
WITH RECURSIVE date_spine AS (
    SELECT DATE('2022-01-01') AS dt
    UNION ALL
    SELECT DATE_ADD(dt, INTERVAL 1 DAY)
    FROM date_spine
    WHERE dt < DATE('2025-12-31')
)
SELECT
    dt                                              AS date,
    DATE_FORMAT(dt, '%Y%m%d')                      AS date_key,
    YEAR(dt)                                        AS year,
    QUARTER(dt)                                     AS quarter,
    CONCAT('Q', QUARTER(dt))                        AS quarter_label,
    MONTH(dt)                                       AS month,
    MONTHNAME(dt)                                   AS month_name,
    DATE_FORMAT(dt, '%b %Y')                        AS month_year,
    DAY(dt)                                         AS day,
    DAYOFWEEK(dt)                                   AS day_of_week,
    DAYNAME(dt)                                     AS day_name,
    CASE WHEN DAYOFWEEK(dt) IN (1, 7) THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    WEEKOFYEAR(dt)                                  AS week_of_year,
    DATE_FORMAT(dt, '%Y-%m')                        AS year_month,
    DATE_FORMAT(dt, '%Y-Q%q')                       AS year_quarter
FROM date_spine;


-- ============================================================
-- VIEW 5: vw_rfm_segments  (for customer behaviour dashboard)
-- ============================================================
CREATE OR REPLACE VIEW vw_rfm_segments AS
WITH rfm_base AS (
    SELECT
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.email,
        r.region_name,
        r.country,
        DATEDIFF('2024-10-31', MAX(o.order_date))            AS recency_days,
        COUNT(DISTINCT o.order_id)                           AS frequency,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100))
            - SUM(o.discount_amount), 2)                      AS monetary
    FROM customers c
    JOIN orders o      ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id   = oi.order_id
    LEFT JOIN regions r ON c.region_id  = r.region_id
    WHERE o.status = 'Delivered'
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email, r.region_name, r.country
),
rfm_scored AS (
    SELECT *,
        6 - NTILE(5) OVER (ORDER BY recency_days ASC)   AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)           AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)            AS m_score
    FROM rfm_base
)
SELECT
    customer_id,
    customer_name,
    email,
    region_name,
    country,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    ROUND((r_score + f_score + m_score) / 3.0, 2) AS rfm_avg_score,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2                  THEN 'Promising'
        WHEN r_score >= 3 AND f_score >= 2 AND m_score >= 3 THEN 'Potential Loyalists'
        WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score >= 3                  THEN 'Cannot Lose Them'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Lost'
        WHEN r_score >= 4 AND f_score = 1 AND m_score = 1   THEN 'New Customers'
        WHEN r_score >= 3 AND m_score >= 3 AND f_score = 1  THEN 'High-Value New'
        ELSE 'Need Attention'
    END AS rfm_segment
FROM rfm_scored;

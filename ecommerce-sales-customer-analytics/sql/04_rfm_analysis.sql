-- ============================================================
-- E-Commerce Analytics Platform
-- Module: Customer RFM Segmentation Analysis
-- Script: sql/04_rfm_analysis.sql
-- Dataset: Brazilian E-Commerce Public Dataset by Olist
-- Reference Date: 2018-10-17 (Day following latest recorded order)
-- ============================================================

USE ecommerce_analytics;

-- ============================================================
-- RFM Methodology & Scoring System:
-- Recency (R): Days between 2018-10-17 and customer's latest delivered purchase.
--              Lower days = more recent = higher score (5 is best).
-- Frequency (F): Total delivered orders per customer_unique_id.
--              Higher count = higher score. Note: >95% have 1 order, so scored conditionally.
-- Monetary (M): Total product spend on delivered orders.
--              Higher revenue = higher score (5 is best).
--
-- Segments Defined:
-- 1. Champions:           R in (4,5) AND F >= 4 AND M in (4,5)
-- 2. Loyal Customers:     R in (3,4,5) AND F >= 2 AND M in (3,4,5)
-- 3. Potential Loyalists: R in (3,4,5) AND F >= 1 AND M in (3,4)
-- 4. New Customers:       R in (4,5) AND F = 1 AND M <= 2
-- 5. Promising:           R = 3 AND F = 1 AND M in (2,3)
-- 6. Need Attention:      R = 3 AND F >= 2
-- 7. At Risk:             R in (1,2) AND F >= 2 AND M in (3,4,5)
-- 8. Cannot Lose Them:    R in (1,2) AND F >= 3 AND M in (4,5)
-- 9. Hibernating:         R in (1,2) AND F = 1 AND M in (2,3)
-- 10. Lost / Inactive:    R = 1 AND F = 1 AND M = 1
-- ============================================================

WITH anchor_date AS (
    -- Dynamic analysis reference date: 1 day following latest purchase in dataset
    -- For real-time production databases, replace with CURRENT_DATE
    SELECT DATE_ADD(MAX(order_purchase_timestamp), INTERVAL 1 DAY) AS ref_date
    FROM orders
    WHERE order_status = 'delivered'
),
rfm_base AS (
    SELECT 
        c.customer_unique_id,
        DATEDIFF((SELECT ref_date FROM anchor_date), MAX(o.order_purchase_timestamp)) AS recency_days,
        COUNT(DISTINCT o.order_id)                             AS frequency,
        ROUND(SUM(oi.price), 2)                                AS monetary
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
rfm_scored AS (
    SELECT 
        customer_unique_id,
        recency_days,
        frequency,
        monetary,
        -- Recency: 5 quintiles (inverted: lowest days get score 5)
        6 - NTILE(5) OVER (ORDER BY recency_days ASC) AS r_score,
        -- Frequency: Scored deterministically due to extreme 1-order skew in e-commerce
        CASE 
            WHEN frequency >= 4 THEN 5
            WHEN frequency = 3  THEN 4
            WHEN frequency = 2  THEN 3
            ELSE 1
        END AS f_score,
        -- Monetary: 5 quintiles (highest spend gets score 5)
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
),
rfm_segmented AS (
    SELECT 
        customer_unique_id,
        recency_days,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        CONCAT(r_score, f_score, m_score) AS rfm_cell,
        (r_score + f_score + m_score)     AS rfm_total_score,
        CASE 
            WHEN r_score >= 4 AND f_score >= 3 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 2 AND m_score >= 3 THEN 'Loyal Customers'
            WHEN r_score >= 3 AND f_score >= 2                 THEN 'Potential Loyalists'
            WHEN r_score >= 4 AND f_score = 1 AND m_score <= 2 THEN 'Recent New Customers'
            WHEN r_score >= 4 AND f_score = 1 AND m_score >= 3 THEN 'Promising High-Spender'
            WHEN r_score = 3 AND f_score = 1                   THEN 'Promising Regular'
            WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 4 THEN 'Cannot Lose Them'
            WHEN r_score <= 2 AND f_score >= 2                 THEN 'At Risk'
            WHEN r_score <= 2 AND f_score = 1 AND m_score >= 3 THEN 'Hibernating Value'
            ELSE 'Lost / Inactive'
        END AS customer_segment
    FROM rfm_scored
)

-- ============================================================
-- Query 1: Segment Strategic Summary & Revenue Contribution
-- ============================================================
SELECT 
    customer_segment,
    COUNT(customer_unique_id)                                           AS total_customers,
    ROUND(COUNT(customer_unique_id) / (SELECT COUNT(*) FROM rfm_segmented) * 100, 2) AS customer_share_pct,
    ROUND(AVG(recency_days), 1)                                         AS avg_recency_days,
    ROUND(AVG(frequency), 2)                                            AS avg_frequency,
    ROUND(AVG(monetary), 2)                                             AS avg_monetary_clv,
    ROUND(SUM(monetary), 2)                                             AS total_segment_revenue,
    ROUND(SUM(monetary) / (SELECT SUM(monetary) FROM rfm_segmented) * 100, 2) AS revenue_share_pct
FROM rfm_segmented
GROUP BY customer_segment
ORDER BY total_segment_revenue DESC;


-- ============================================================
-- Query 2: Segment Actionable Playbook Mapping
-- Provides the business context for marketing activation
-- ============================================================
WITH anchor_date AS (
    SELECT DATE_ADD(MAX(order_purchase_timestamp), INTERVAL 1 DAY) AS ref_date
    FROM orders
    WHERE order_status = 'delivered'
),
rfm_base AS (
    SELECT 
        c.customer_unique_id,
        DATEDIFF((SELECT ref_date FROM anchor_date), MAX(o.order_purchase_timestamp)) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(oi.price), 2) AS monetary
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
rfm_scored AS (
    SELECT 
        customer_unique_id,
        recency_days,
        frequency,
        monetary,
        6 - NTILE(5) OVER (ORDER BY recency_days ASC) AS r_score,
        CASE 
            WHEN frequency >= 4 THEN 5
            WHEN frequency = 3  THEN 4
            WHEN frequency = 2  THEN 3
            ELSE 1
        END AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
),
rfm_segmented AS (
    SELECT 
        customer_unique_id,
        monetary,
        CASE 
            WHEN r_score >= 4 AND f_score >= 3 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 2 AND m_score >= 3 THEN 'Loyal Customers'
            WHEN r_score >= 3 AND f_score >= 2                 THEN 'Potential Loyalists'
            WHEN r_score >= 4 AND f_score = 1 AND m_score <= 2 THEN 'Recent New Customers'
            WHEN r_score >= 4 AND f_score = 1 AND m_score >= 3 THEN 'Promising High-Spender'
            WHEN r_score = 3 AND f_score = 1                   THEN 'Promising Regular'
            WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 4 THEN 'Cannot Lose Them'
            WHEN r_score <= 2 AND f_score >= 2                 THEN 'At Risk'
            WHEN r_score <= 2 AND f_score = 1 AND m_score >= 3 THEN 'Hibernating Value'
            ELSE 'Lost / Inactive'
        END AS customer_segment
    FROM rfm_scored
)
SELECT 
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(SUM(monetary), 2) AS segment_revenue,
    CASE customer_segment
        WHEN 'Champions'              THEN 'Offer VIP loyalty perks, early product releases, seek reviews'
        WHEN 'Loyal Customers'        THEN 'Upsell higher-value products, introduce points rewards program'
        WHEN 'Potential Loyalists'     THEN 'Recommend membership benefits, cross-sell complementary categories'
        WHEN 'Recent New Customers'   THEN 'Deploy onboarding sequence, provide first repeat-purchase discount'
        WHEN 'Promising High-Spender' THEN 'Assign dedicated support, showcase premium catalog categories'
        WHEN 'Promising Regular'      THEN 'Send personalized category suggestions, nurture engagement'
        WHEN 'Cannot Lose Them'       THEN 'Immediate high-touch winback email, aggressive discount vouchers'
        WHEN 'At Risk'                THEN 'Re-engagement campaigns with tailored offers, customer surveys'
        WHEN 'Hibernating Value'      THEN 'Seasonal revival discounts, highlight major new arrivals'
        ELSE 'Low-cost automated email reactivation or purge from active retargeting'
    END AS marketing_action_strategy
FROM rfm_segmented
GROUP BY customer_segment, marketing_action_strategy
ORDER BY segment_revenue DESC;

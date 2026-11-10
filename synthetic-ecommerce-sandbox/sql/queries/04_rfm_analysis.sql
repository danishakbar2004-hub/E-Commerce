-- ============================================================
-- SQL ANALYTICS QUERIES
-- File: 04_rfm_analysis.sql
-- RFM = Recency, Frequency, Monetary
-- ============================================================

-- ============================================================
-- STEP 1: Compute raw RFM values per customer
-- Concepts: CTEs, DATE functions, aggregation
-- ============================================================
WITH rfm_base AS (
    SELECT
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name)              AS customer_name,
        c.email,
        -- Recency: days since last purchase (lower = better)
        DATEDIFF('2024-10-31', MAX(o.order_date))            AS recency_days,
        -- Frequency: number of orders
        COUNT(DISTINCT o.order_id)                           AS frequency,
        -- Monetary: total spend
        ROUND(
            SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100))
            - SUM(o.discount_amount),
            2
        )                                                    AS monetary
    FROM customers c
    JOIN orders o      ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id   = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email
),

-- ============================================================
-- STEP 2: Score each RFM dimension 1-5 using NTILE
-- ============================================================
rfm_scored AS (
    SELECT
        customer_id,
        customer_name,
        email,
        recency_days,
        frequency,
        monetary,
        -- Recency: lower days = better = score 5
        6 - NTILE(5) OVER (ORDER BY recency_days ASC)   AS r_score,
        -- Frequency: higher orders = better = score 5
        NTILE(5) OVER (ORDER BY frequency ASC)           AS f_score,
        -- Monetary: higher spend = better = score 5
        NTILE(5) OVER (ORDER BY monetary ASC)            AS m_score
    FROM rfm_base
),

-- ============================================================
-- STEP 3: Combine scores and assign segments
-- ============================================================
rfm_segments AS (
    SELECT
        customer_id,
        customer_name,
        email,
        recency_days,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        CONCAT(r_score, f_score, m_score)   AS rfm_code,
        ROUND((r_score + f_score + m_score) / 3.0, 2) AS rfm_avg_score,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4
                THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3
                THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score <= 2
                THEN 'Promising'
            WHEN r_score >= 3 AND f_score >= 2 AND m_score >= 3
                THEN 'Potential Loyalists'
            WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4
                THEN 'At Risk'
            WHEN r_score <= 2 AND f_score >= 3
                THEN 'Cannot Lose Them'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2
                THEN 'Lost'
            WHEN r_score >= 4 AND f_score = 1 AND m_score = 1
                THEN 'New Customers'
            WHEN r_score >= 3 AND m_score >= 3 AND f_score = 1
                THEN 'High-Value New'
            ELSE 'Need Attention'
        END AS rfm_segment
    FROM rfm_scored
)

-- ============================================================
-- STEP 4: Final output with segment summary
-- ============================================================
SELECT
    customer_id,
    customer_name,
    email,
    recency_days,
    frequency          AS purchase_frequency,
    monetary           AS total_spend,
    r_score,
    f_score,
    m_score,
    rfm_code,
    rfm_avg_score,
    rfm_segment
FROM rfm_segments
ORDER BY rfm_avg_score DESC, monetary DESC;


-- ============================================================
-- RFM SEGMENT SUMMARY (for dashboard KPI cards)
-- ============================================================
WITH rfm_base AS (
    SELECT
        c.customer_id,
        DATEDIFF('2024-10-31', MAX(o.order_date))            AS recency_days,
        COUNT(DISTINCT o.order_id)                           AS frequency,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100))
            - SUM(o.discount_amount), 2)                      AS monetary
    FROM customers c
    JOIN orders o      ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id   = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY c.customer_id
),
rfm_scored AS (
    SELECT
        customer_id, recency_days, frequency, monetary,
        6 - NTILE(5) OVER (ORDER BY recency_days ASC)   AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)           AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)            AS m_score
    FROM rfm_base
),
rfm_segments AS (
    SELECT *,
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
    FROM rfm_scored
)
SELECT
    rfm_segment,
    COUNT(*)                           AS customer_count,
    ROUND(AVG(recency_days), 1)        AS avg_recency_days,
    ROUND(AVG(frequency), 2)           AS avg_frequency,
    ROUND(AVG(monetary), 2)            AS avg_monetary,
    ROUND(SUM(monetary), 2)            AS total_revenue,
    ROUND(SUM(monetary) / (SELECT SUM(monetary) FROM rfm_segments) * 100, 2)
                                       AS revenue_share_pct
FROM rfm_segments
GROUP BY rfm_segment
ORDER BY total_revenue DESC;


-- ============================================================
-- RFM RECOMMENDED ACTIONS (Marketing playbook)
-- ============================================================
SELECT
    rfm_segment,
    COUNT(*) AS customers,
    marketing_action
FROM (
    -- (Reuse rfm_segments CTE above, joined with action mapping)
    SELECT
        rfm_segment,
        CASE rfm_segment
            WHEN 'Champions'          THEN 'Reward & ask for reviews/referrals'
            WHEN 'Loyal Customers'    THEN 'Upsell higher-value products, loyalty rewards'
            WHEN 'Potential Loyalists' THEN 'Membership/loyalty program offer'
            WHEN 'Promising'          THEN 'Onboarding sequence, early-bird offers'
            WHEN 'High-Value New'     THEN 'Premium onboarding, personal outreach'
            WHEN 'Need Attention'     THEN 'Win-back campaign, special discounts'
            WHEN 'At Risk'            THEN 'Send personalised emails, special offers'
            WHEN 'Cannot Lose Them'   THEN 'Reactivation campaign, survey feedback'
            WHEN 'Lost'               THEN 'Dormant list; occasional re-engagement'
            ELSE 'Monitor & nurture'
        END AS marketing_action
    FROM (
        SELECT rfm_segment FROM rfm_segments  -- reference CTE from above
    ) s
) t
GROUP BY rfm_segment, marketing_action
ORDER BY customers DESC;

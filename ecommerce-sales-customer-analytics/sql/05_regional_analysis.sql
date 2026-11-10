-- ============================================================
-- E-Commerce Analytics Platform
-- Module: Regional & Geographic Analysis
-- Script: sql/05_regional_analysis.sql
-- Dataset: Brazilian E-Commerce Public Dataset by Olist
-- ============================================================

USE ecommerce_analytics;

-- ============================================================
-- 1. Revenue, Order Volume, and Customers by Customer State
-- Demonstrates: Geographic grouping, national averages, share of wallet
-- ============================================================
WITH state_metrics AS (
    SELECT 
        c.customer_state,
        COUNT(DISTINCT c.customer_unique_id) AS total_customers,
        COUNT(DISTINCT o.order_id)           AS total_orders,
        COUNT(oi.order_item_id)              AS total_items_sold,
        ROUND(SUM(oi.price), 2)              AS total_revenue,
        ROUND(SUM(oi.freight_value), 2)      AS total_freight_paid
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_state
)
SELECT 
    customer_state,
    total_customers,
    total_orders,
    total_items_sold,
    total_revenue,
    total_freight_paid,
    ROUND(total_revenue / total_orders, 2) AS state_aov,
    ROUND(total_revenue / SUM(total_revenue) OVER () * 100, 2) AS revenue_share_pct,
    DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS state_revenue_rank
FROM state_metrics
ORDER BY total_revenue DESC;


-- ============================================================
-- 2. State Performance Comparison: Revenue Rank vs Order Volume Rank
-- Identifies regions with high-ticket orders vs volume-driven states
-- ============================================================
WITH state_ranks AS (
    SELECT 
        c.customer_state,
        ROUND(SUM(oi.price), 2)    AS total_revenue,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2) AS aov,
        DENSE_RANK() OVER (ORDER BY SUM(oi.price) DESC) AS revenue_rank,
        DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT o.order_id) DESC) AS volume_rank
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_state
)
SELECT 
    customer_state,
    total_revenue,
    revenue_rank,
    total_orders,
    volume_rank,
    aov,
    CASE 
        WHEN revenue_rank < volume_rank THEN 'Premium Market (Higher AOV)'
        WHEN revenue_rank > volume_rank THEN 'Volume-Driven (Lower AOV)'
        ELSE 'Balanced'
    END AS market_profile
FROM state_ranks
ORDER BY revenue_rank ASC
LIMIT 15;


-- ============================================================
-- 3. Average Delivery Duration and Logistics Performance by Customer State
-- Evaluates fulfillment SLA across Brazilian states
-- ============================================================
SELECT 
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 1) AS avg_actual_delivery_days,
    ROUND(AVG(DATEDIFF(o.order_estimated_delivery_date, o.order_purchase_timestamp)), 1) AS avg_estimated_delivery_days,
    ROUND(AVG(oi.freight_value), 2) AS avg_freight_cost_per_item,
    ROUND(
        SUM(CASE WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1 ELSE 0 END) 
        / COUNT(DISTINCT o.order_id) * 100, 
        2
    ) AS on_time_delivery_rate_pct
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered' 
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
HAVING delivered_orders >= 50
ORDER BY avg_actual_delivery_days ASC;


-- ============================================================
-- 4. Seller Concentration vs Customer Origin (Inter-State Flow)
-- Compares Merchant Hubs (Seller State) to Buyer Demand (Customer State)
-- ============================================================
WITH seller_origin AS (
    SELECT 
        s.seller_state,
        COUNT(DISTINCT s.seller_id) AS active_sellers,
        ROUND(SUM(oi.price), 2)     AS total_sales_fulfilled
    FROM sellers s
    INNER JOIN order_items oi ON s.seller_id = oi.seller_id
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY s.seller_state
),
customer_demand AS (
    SELECT 
        c.customer_state,
        COUNT(DISTINCT c.customer_unique_id) AS active_buyers,
        ROUND(SUM(oi.price), 2)              AS total_demand_spend
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_state
)
SELECT 
    COALESCE(so.seller_state, cd.customer_state) AS state,
    COALESCE(so.active_sellers, 0)               AS active_sellers,
    COALESCE(cd.active_buyers, 0)                AS active_buyers,
    COALESCE(so.total_sales_fulfilled, 0)        AS seller_revenue_fulfilled,
    COALESCE(cd.total_demand_spend, 0)           AS customer_spending,
    ROUND(COALESCE(so.total_sales_fulfilled, 0) - COALESCE(cd.total_demand_spend, 0), 2) AS net_trade_balance,
    CASE 
        WHEN COALESCE(so.total_sales_fulfilled, 0) > COALESCE(cd.total_demand_spend, 0) * 1.5 THEN 'Net Merchant Hub (Exporter)'
        WHEN COALESCE(cd.total_demand_spend, 0) > COALESCE(so.total_sales_fulfilled, 0) * 1.5 THEN 'Net Consumer Market (Importer)'
        ELSE 'Balanced Market'
    END AS regional_trade_role
FROM seller_origin so
LEFT JOIN customer_demand cd ON so.seller_state = cd.customer_state
ORDER BY seller_revenue_fulfilled DESC;

-- ============================================================
-- E-Commerce Analytics Platform
-- Database: MySQL 8.0+
-- Script: 03_data_validation.sql
-- Dataset: Brazilian E-Commerce Public Dataset by Olist
-- Description: Comprehensive data quality & relationship validation suite
-- ============================================================

USE ecommerce_analytics;

-- ============================================================
-- SECTION 1: Row Count Verification
-- Expected ranges:
-- customers: ~99,441 | orders: ~99,441 | order_items: ~112,650
-- order_payments: ~103,886 | order_reviews: ~99,224 - 100,000
-- products: ~32,951 | sellers: ~3,095 | geolocation: ~1,000,163
-- product_category_translation: ~71
-- ============================================================
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'geolocation', COUNT(*) FROM geolocation
UNION ALL
SELECT 'product_category_translation', COUNT(*) FROM product_category_translation;

-- ============================================================
-- SECTION 2: Null Value Analysis across Key Columns
-- ============================================================
SELECT 
    'orders' AS entity,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) AS null_approved_at,
    SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) AS null_carrier_date,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS null_customer_delivered_date
FROM orders;

SELECT 
    'products' AS entity,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS null_category_name,
    SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END) AS null_weight
FROM products;

-- ============================================================
-- SECTION 3: Order Status Distribution
-- Note: 'delivered' represents ~97% of completed transactions.
-- 'canceled' and 'unavailable' must be excluded from revenue KPIs.
-- ============================================================
SELECT 
    order_status,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM orders) * 100, 2) AS percentage
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;

-- ============================================================
-- SECTION 4: Duplicate & Cardinality Checks
-- ============================================================
-- Customer Unique ID vs Customer ID
SELECT 
    COUNT(customer_id) AS total_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS total_unique_individuals,
    COUNT(customer_id) - COUNT(DISTINCT customer_unique_id) AS repeat_purchase_indicators
FROM customers;

-- Duplicate review surveys per order
SELECT 
    order_id,
    COUNT(review_id) AS review_submissions
FROM order_reviews
GROUP BY order_id
HAVING COUNT(review_id) > 1
ORDER BY review_submissions DESC
LIMIT 10;

-- ============================================================
-- SECTION 5: Referential Integrity & Orphan Records
-- ============================================================
-- Orders with missing customer records
SELECT COUNT(*) AS orphaned_orders
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Order items with missing order headers
SELECT COUNT(*) AS orphaned_order_items
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Order items with missing products
SELECT COUNT(*) AS orphaned_products
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Orders without matching payment records
SELECT COUNT(*) AS orders_without_payments
FROM orders o
LEFT JOIN order_payments op ON o.order_id = op.order_id
WHERE op.order_id IS NULL;

-- ============================================================
-- SECTION 6: Temporal Integrity Checks
-- ============================================================
-- Check for negative delivery duration (delivered before purchased)
SELECT 
    order_id,
    order_purchase_timestamp,
    order_delivered_customer_date
FROM orders
WHERE order_delivered_customer_date < order_purchase_timestamp;

-- Overall dataset date range
SELECT 
    MIN(order_purchase_timestamp) AS earliest_order,
    MAX(order_purchase_timestamp) AS latest_order,
    DATEDIFF(MAX(order_purchase_timestamp), MIN(order_purchase_timestamp)) AS total_days_span
FROM orders;

-- ============================================================
-- SECTION 7: Monetary Sanity Checks
-- Comparing Item Gross Price Sum to Payment Value
-- ============================================================
WITH item_totals AS (
    SELECT 
        order_id,
        SUM(price) AS items_revenue,
        SUM(freight_value) AS items_freight,
        SUM(price + freight_value) AS calculated_order_total
    FROM order_items
    GROUP BY order_id
),
payment_totals AS (
    SELECT 
        order_id,
        SUM(payment_value) AS total_paid
    FROM order_payments
    GROUP BY order_id
)
SELECT 
    COUNT(*) AS evaluated_orders,
    ROUND(SUM(it.calculated_order_total), 2) AS total_items_plus_freight,
    ROUND(SUM(pt.total_paid), 2) AS total_payments_registered,
    ROUND(ABS(SUM(it.calculated_order_total) - SUM(pt.total_paid)), 2) AS variance
FROM item_totals it
INNER JOIN payment_totals pt ON it.order_id = pt.order_id;

-- Summary of delivered orders revenue baseline
SELECT 
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    COUNT(DISTINCT c.customer_unique_id) AS unique_purchasers,
    ROUND(SUM(oi.price), 2) AS total_item_revenue,
    ROUND(SUM(oi.freight_value), 2) AS total_freight_revenue,
    ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2) AS delivered_aov
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';

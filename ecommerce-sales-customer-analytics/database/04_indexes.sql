-- ============================================================
-- E-Commerce Analytics Platform
-- Database: MySQL 8.0+
-- Script: 04_indexes.sql
-- Dataset: Brazilian E-Commerce Public Dataset by Olist
-- Description: Performance optimization indexes for analytical queries
-- ============================================================

USE ecommerce_analytics;

-- ============================================================
-- 1. Orders Indexes
-- Speeds up status filtering, customer joins, and date-range aggregations
-- ============================================================
CREATE INDEX idx_orders_customer_id 
    ON orders(customer_id);

CREATE INDEX idx_orders_status 
    ON orders(order_status);

CREATE INDEX idx_orders_purchase_timestamp 
    ON orders(order_purchase_timestamp);

-- Composite index for the most common analytical filter pattern
CREATE INDEX idx_orders_status_timestamp 
    ON orders(order_status, order_purchase_timestamp);

-- ============================================================
-- 2. Customers Indexes
-- Critical for customer segmentation and distinct customer deduplication
-- ============================================================
CREATE INDEX idx_customers_unique_id 
    ON customers(customer_unique_id);

CREATE INDEX idx_customers_state 
    ON customers(customer_state);

CREATE INDEX idx_customers_zip 
    ON customers(customer_zip_code_prefix);

-- ============================================================
-- 3. Order Items Indexes
-- Speeds up product lookups and merchant fulfillment analytics
-- ============================================================
CREATE INDEX idx_order_items_product_id 
    ON order_items(product_id);

CREATE INDEX idx_order_items_seller_id 
    ON order_items(seller_id);

-- ============================================================
-- 4. Order Payments Indexes
-- Optimizes payment method breakdowns and installment analysis
-- ============================================================
CREATE INDEX idx_order_payments_type 
    ON order_payments(payment_type);

-- ============================================================
-- 5. Order Reviews Indexes
-- Speeds up sentiment filtering and score evaluations
-- ============================================================
CREATE INDEX idx_order_reviews_score 
    ON order_reviews(review_score);

-- ============================================================
-- 6. Products Indexes
-- Optimizes category filtering and translation joins
-- ============================================================
CREATE INDEX idx_products_category 
    ON products(product_category_name);

-- ============================================================
-- 7. Sellers & Geolocation Indexes
-- Optimizes geographic joins and regional aggregations
-- ============================================================
CREATE INDEX idx_sellers_state 
    ON sellers(seller_state);

CREATE INDEX idx_geolocation_zip 
    ON geolocation(geolocation_zip_code_prefix);

-- ============================================================
-- Verify Index Creation
-- ============================================================
SHOW INDEX FROM orders;
SHOW INDEX FROM customers;
SHOW INDEX FROM order_items;
SHOW INDEX FROM order_payments;
SHOW INDEX FROM products;

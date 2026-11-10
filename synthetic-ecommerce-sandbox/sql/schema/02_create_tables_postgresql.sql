-- ============================================================
-- E-Commerce Analytics Database Schema
-- PostgreSQL 13+ Version
-- ============================================================

DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS regions CASCADE;

-- ============================================================
-- 1. REGIONS
-- ============================================================
CREATE TABLE regions (
    region_id    SERIAL PRIMARY KEY,
    region_name  VARCHAR(100) NOT NULL,
    country      VARCHAR(100) NOT NULL,
    timezone     VARCHAR(50)
);

-- ============================================================
-- 2. CUSTOMERS
-- ============================================================
CREATE TABLE customers (
    customer_id  SERIAL PRIMARY KEY,
    first_name   VARCHAR(100) NOT NULL,
    last_name    VARCHAR(100) NOT NULL,
    email        VARCHAR(255) UNIQUE NOT NULL,
    phone        VARCHAR(20),
    region_id    INT REFERENCES regions(region_id),
    city         VARCHAR(100),
    signup_date  DATE NOT NULL,
    is_active    BOOLEAN DEFAULT TRUE
);

-- ============================================================
-- 3. CATEGORIES
-- ============================================================
CREATE TABLE categories (
    category_id    SERIAL PRIMARY KEY,
    category_name  VARCHAR(100) NOT NULL,
    parent_id      INT REFERENCES categories(category_id)
);

-- ============================================================
-- 4. PRODUCTS
-- ============================================================
CREATE TABLE products (
    product_id    SERIAL PRIMARY KEY,
    product_name  VARCHAR(255) NOT NULL,
    category_id   INT NOT NULL REFERENCES categories(category_id),
    unit_price    NUMERIC(10, 2) NOT NULL,
    cost_price    NUMERIC(10, 2) NOT NULL,
    stock_qty     INT DEFAULT 0,
    is_active     BOOLEAN DEFAULT TRUE,
    launch_date   DATE
);

-- ============================================================
-- 5. ORDERS
-- ============================================================
CREATE TABLE orders (
    order_id        SERIAL PRIMARY KEY,
    customer_id     INT NOT NULL REFERENCES customers(customer_id),
    order_date      TIMESTAMP NOT NULL,
    ship_date       TIMESTAMP,
    status          VARCHAR(20) CHECK (status IN ('Pending','Processing','Shipped','Delivered','Cancelled','Refunded')) DEFAULT 'Pending',
    shipping_fee    NUMERIC(10, 2) DEFAULT 0.00,
    discount_amount NUMERIC(10, 2) DEFAULT 0.00,
    region_id       INT REFERENCES regions(region_id)
);

-- ============================================================
-- 6. ORDER ITEMS
-- ============================================================
CREATE TABLE order_items (
    item_id      SERIAL PRIMARY KEY,
    order_id     INT NOT NULL REFERENCES orders(order_id),
    product_id   INT NOT NULL REFERENCES products(product_id),
    quantity     INT NOT NULL DEFAULT 1,
    unit_price   NUMERIC(10, 2) NOT NULL,
    discount_pct NUMERIC(5, 2) DEFAULT 0.00
);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX idx_orders_date       ON orders(order_date);
CREATE INDEX idx_orders_customer   ON orders(customer_id);
CREATE INDEX idx_orders_status     ON orders(status);
CREATE INDEX idx_items_order       ON order_items(order_id);
CREATE INDEX idx_items_product     ON order_items(product_id);
CREATE INDEX idx_customers_region  ON customers(region_id);
CREATE INDEX idx_products_category ON products(category_id);

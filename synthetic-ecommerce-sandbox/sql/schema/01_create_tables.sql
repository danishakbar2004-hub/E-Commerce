-- ============================================================
-- E-Commerce Analytics Database Schema
-- Compatible with: MySQL 8.0+ / PostgreSQL 13+
-- ============================================================

-- Drop existing tables (in dependency order)
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS regions;

-- ============================================================
-- 1. REGIONS
-- ============================================================
CREATE TABLE regions (
    region_id    INT PRIMARY KEY AUTO_INCREMENT,  -- Use SERIAL in PostgreSQL
    region_name  VARCHAR(100) NOT NULL,
    country      VARCHAR(100) NOT NULL,
    timezone     VARCHAR(50)
);

-- ============================================================
-- 2. CUSTOMERS
-- ============================================================
CREATE TABLE customers (
    customer_id      INT PRIMARY KEY AUTO_INCREMENT,
    first_name       VARCHAR(100) NOT NULL,
    last_name        VARCHAR(100) NOT NULL,
    email            VARCHAR(255) UNIQUE NOT NULL,
    phone            VARCHAR(20),
    region_id        INT,
    city             VARCHAR(100),
    signup_date      DATE NOT NULL,
    is_active        BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_customer_region FOREIGN KEY (region_id) REFERENCES regions(region_id)
);

-- ============================================================
-- 3. CATEGORIES
-- ============================================================
CREATE TABLE categories (
    category_id    INT PRIMARY KEY AUTO_INCREMENT,
    category_name  VARCHAR(100) NOT NULL,
    parent_id      INT NULL,  -- NULL = top-level category
    CONSTRAINT fk_category_parent FOREIGN KEY (parent_id) REFERENCES categories(category_id)
);

-- ============================================================
-- 4. PRODUCTS
-- ============================================================
CREATE TABLE products (
    product_id    INT PRIMARY KEY AUTO_INCREMENT,
    product_name  VARCHAR(255) NOT NULL,
    category_id   INT NOT NULL,
    unit_price    DECIMAL(10, 2) NOT NULL,
    cost_price    DECIMAL(10, 2) NOT NULL,
    stock_qty     INT DEFAULT 0,
    is_active     BOOLEAN DEFAULT TRUE,
    launch_date   DATE,
    CONSTRAINT fk_product_category FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

-- ============================================================
-- 5. ORDERS
-- ============================================================
CREATE TABLE orders (
    order_id        INT PRIMARY KEY AUTO_INCREMENT,
    customer_id     INT NOT NULL,
    order_date      DATETIME NOT NULL,
    ship_date       DATETIME,
    status          ENUM('Pending','Processing','Shipped','Delivered','Cancelled','Refunded') DEFAULT 'Pending',
    shipping_fee    DECIMAL(10, 2) DEFAULT 0.00,
    discount_amount DECIMAL(10, 2) DEFAULT 0.00,
    region_id       INT,
    CONSTRAINT fk_order_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_order_region   FOREIGN KEY (region_id)   REFERENCES regions(region_id)
);

-- ============================================================
-- 6. ORDER ITEMS
-- ============================================================
CREATE TABLE order_items (
    item_id      INT PRIMARY KEY AUTO_INCREMENT,
    order_id     INT NOT NULL,
    product_id   INT NOT NULL,
    quantity     INT NOT NULL DEFAULT 1,
    unit_price   DECIMAL(10, 2) NOT NULL,  -- Price at time of purchase
    discount_pct DECIMAL(5, 2) DEFAULT 0.00,
    CONSTRAINT fk_item_order   FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    CONSTRAINT fk_item_product FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- ============================================================
-- INDEXES for query performance
-- ============================================================
CREATE INDEX idx_orders_date       ON orders(order_date);
CREATE INDEX idx_orders_customer   ON orders(customer_id);
CREATE INDEX idx_orders_status     ON orders(status);
CREATE INDEX idx_items_order       ON order_items(order_id);
CREATE INDEX idx_items_product     ON order_items(product_id);
CREATE INDEX idx_customers_region  ON customers(region_id);
CREATE INDEX idx_products_category ON products(category_id);

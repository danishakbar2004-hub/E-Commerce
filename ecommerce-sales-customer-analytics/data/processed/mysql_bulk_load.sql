
-- ============================================================
-- MySQL High-Speed Bulk Ingestion Script
-- Run these commands in MySQL Workbench or CLI
-- ============================================================
USE ecommerce_analytics;
SET FOREIGN_KEY_CHECKS = 0;

LOAD DATA LOCAL INFILE 'C:/Users/Danish Akbar/E-Commerce/ecommerce-sales-customer-analytics/data/processed/product_category_translation_processed.csv'
INTO TABLE product_category_translation
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/Danish Akbar/E-Commerce/ecommerce-sales-customer-analytics/data/processed/products_processed.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/Danish Akbar/E-Commerce/ecommerce-sales-customer-analytics/data/processed/sellers_processed.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/Danish Akbar/E-Commerce/ecommerce-sales-customer-analytics/data/processed/customers_processed.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/Danish Akbar/E-Commerce/ecommerce-sales-customer-analytics/data/processed/orders_processed.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/Danish Akbar/E-Commerce/ecommerce-sales-customer-analytics/data/processed/order_items_processed.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/Danish Akbar/E-Commerce/ecommerce-sales-customer-analytics/data/processed/order_payments_processed.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/Danish Akbar/E-Commerce/ecommerce-sales-customer-analytics/data/processed/order_reviews_processed.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 LINES;

SET FOREIGN_KEY_CHECKS = 1;

"""
================================================================================
E-Commerce Analytics Platform
Dataset: Brazilian E-Commerce Public Dataset by Olist (Kaggle)
Script: python/data_preparation.py
Purpose: Production-grade data cleaning, validation, relationship integrity checks,
         and export of processed tables for MySQL loading and Power BI modeling.
================================================================================
"""

import os
import sys
import argparse
import logging
from datetime import datetime
from pathlib import Path
import pandas as pd
import numpy as np


# Setup relative base directories dynamically
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_DIR = SCRIPT_DIR.parent
DEFAULT_RAW_DIR = PROJECT_DIR / "data" / "raw"
DEFAULT_PROCESSED_DIR = PROJECT_DIR / "data" / "processed"


def setup_logging(log_path: Path) -> logging.Logger:
    """Configures multi-channel logging to console and persistent log file."""
    log_path.parent.mkdir(parents=True, exist_ok=True)
    logger = logging.getLogger("OlistDataPrep")
    logger.setLevel(logging.INFO)
    logger.handlers.clear()

    formatter = logging.Formatter(
        "[%(asctime)s] [%(levelname)s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S"
    )

    fh = logging.FileHandler(log_path, mode="w", encoding="utf-8")
    fh.setLevel(logging.INFO)
    fh.setFormatter(formatter)
    logger.addHandler(fh)

    ch = logging.StreamHandler(sys.stdout)
    ch.setLevel(logging.INFO)
    ch.setFormatter(formatter)
    logger.addHandler(ch)

    return logger


def load_csv(filepath: Path, name: str, logger: logging.Logger) -> pd.DataFrame:
    """Loads CSV with validation and diagnostics."""
    if not filepath.exists():
        logger.error(f"Required raw file not found: {filepath}")
        return None
    try:
        df = pd.read_csv(filepath, low_memory=False)
        logger.info(f"Loaded '{name}': {df.shape[0]:,} rows, {df.shape[1]} columns.")
        return df
    except Exception as e:
        logger.error(f"Error reading '{filepath}': {str(e)}")
        return None


def clean_customers(df: pd.DataFrame, logger: logging.Logger) -> pd.DataFrame:
    """Cleans customer records and standardizes geographic strings."""
    logger.info("Cleaning customers dataset...")
    initial_len = len(df)
    
    df['customer_city'] = df['customer_city'].astype(str).str.strip().str.title()
    df['customer_state'] = df['customer_state'].astype(str).str.strip().str.upper()
    df['customer_zip_code_prefix'] = df['customer_zip_code_prefix'].astype(str).str.zfill(5)
    
    df = df.dropna(subset=['customer_id', 'customer_unique_id'])
    logger.info(f"Customers cleaned: {len(df):,} records (Dropped {initial_len - len(df)}).")
    
    return df[['customer_id', 'customer_unique_id', 'customer_zip_code_prefix', 'customer_city', 'customer_state']]


def clean_orders(df: pd.DataFrame, logger: logging.Logger) -> pd.DataFrame:
    """Parses timestamps, validates status and identifies temporal anomalies."""
    logger.info("Cleaning orders dataset...")
    time_cols = [
        'order_purchase_timestamp',
        'order_approved_at',
        'order_delivered_carrier_date',
        'order_delivered_customer_date',
        'order_estimated_delivery_date'
    ]
    for col in time_cols:
        df[col] = pd.to_datetime(df[col], errors='coerce')
    
    # Validation: Flag delivery anomalies where delivery preceded purchase
    anomalies = (df['order_delivered_customer_date'] < df['order_purchase_timestamp']).sum()
    if anomalies > 0:
        logger.warning(f"Identified {anomalies} orders with delivery date preceding purchase timestamp.")
    
    df['order_status'] = df['order_status'].astype(str).str.strip().str.lower()
    logger.info(f"Orders cleaned: {len(df):,} records.")
    
    # Return schema-compatible columns
    return df[[
        'order_id', 'customer_id', 'order_status',
        'order_purchase_timestamp', 'order_approved_at',
        'order_delivered_carrier_date', 'order_delivered_customer_date',
        'order_estimated_delivery_date'
    ]]


def clean_order_items(df: pd.DataFrame, logger: logging.Logger) -> pd.DataFrame:
    """Validates monetary prices, freight, and shipping deadlines."""
    logger.info("Cleaning order_items dataset...")
    df['shipping_limit_date'] = pd.to_datetime(df['shipping_limit_date'], errors='coerce')
    df['price'] = pd.to_numeric(df['price'], errors='coerce')
    df['freight_value'] = pd.to_numeric(df['freight_value'], errors='coerce')
    
    anomalies = ((df['price'] <= 0) | (df['freight_value'] < 0)).sum()
    if anomalies > 0:
        logger.warning(f"Identified {anomalies} items with non-positive price or negative freight.")
        
    logger.info(f"Order items cleaned: {len(df):,} records.")
    return df[[
        'order_id', 'order_item_id', 'product_id', 'seller_id',
        'shipping_limit_date', 'price', 'freight_value'
    ]]


def clean_order_payments(df: pd.DataFrame, logger: logging.Logger):
    """Validates payments and creates pre-aggregated order-level table."""
    logger.info("Cleaning order_payments dataset...")
    df['payment_value'] = pd.to_numeric(df['payment_value'], errors='coerce').fillna(0.0)
    df['payment_type'] = df['payment_type'].astype(str).str.strip().str.lower()
    df['payment_installments'] = pd.to_numeric(df['payment_installments'], errors='coerce').fillna(1).astype(int)
    df['payment_sequential'] = pd.to_numeric(df['payment_sequential'], errors='coerce').fillna(1).astype(int)
    
    # Line-item level payments table (matches schema)
    clean_payments = df[[
        'order_id', 'payment_sequential', 'payment_type',
        'payment_installments', 'payment_value'
    ]].copy()
    
    # Pre-aggregated table to prevent fan-out in BI joins
    payments_agg = df.groupby('order_id').agg(
        total_payment_value=('payment_value', 'sum'),
        payment_sequential_count=('payment_sequential', 'count'),
        max_installments=('payment_installments', 'max'),
        payment_types_used=('payment_type', lambda x: '|'.join(sorted(set(x))))
    ).reset_index()
    
    logger.info(f"Order payments cleaned: {len(clean_payments):,} rows, {len(payments_agg):,} aggregated orders.")
    return clean_payments, payments_agg


def clean_order_reviews(df: pd.DataFrame, logger: logging.Logger) -> pd.DataFrame:
    """Deduplicates multiple survey submissions and standardizes dates."""
    logger.info("Cleaning order_reviews dataset...")
    df['review_creation_date'] = pd.to_datetime(df['review_creation_date'], errors='coerce')
    df['review_answer_timestamp'] = pd.to_datetime(df['review_answer_timestamp'], errors='coerce')
    df['review_score'] = pd.to_numeric(df['review_score'], errors='coerce').fillna(0).astype(int)
    
    # Clean string columns
    df['review_comment_title'] = df['review_comment_title'].fillna('')
    df['review_comment_message'] = df['review_comment_message'].fillna('')
    
    initial_len = len(df)
    # Deduplicate: if an order received multiple reviews, keep the latest answer timestamp
    df = df.sort_values('review_answer_timestamp', ascending=False)
    deduped_reviews = df.drop_duplicates(subset=['order_id'], keep='first').copy()
    logger.info(f"Order reviews cleaned: {len(deduped_reviews):,} unique orders (Deduplicated {initial_len - len(deduped_reviews)}).")
    
    return deduped_reviews[[
        'review_id', 'order_id', 'review_score',
        'review_comment_title', 'review_comment_message',
        'review_creation_date', 'review_answer_timestamp'
    ]]


def clean_products(df: pd.DataFrame, logger: logging.Logger) -> pd.DataFrame:
    """Imputes missing categories and standardizes attribute column names."""
    logger.info("Cleaning products dataset...")
    
    col_mapping = {
        'product_name_lenght': 'product_name_length',
        'product_description_lenght': 'product_description_length'
    }
    df = df.rename(columns=col_mapping)
    
    df['product_category_name'] = df['product_category_name'].fillna('sem_categoria')
    
    numeric_cols = [
        'product_name_length', 'product_description_length', 'product_photos_qty',
        'product_weight_g', 'product_length_cm', 'product_height_cm', 'product_width_cm'
    ]
    for col in numeric_cols:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors='coerce')
            
    logger.info(f"Products cleaned: {len(df):,} records.")
    return df[[
        'product_id', 'product_category_name', 'product_name_length',
        'product_description_length', 'product_photos_qty', 'product_weight_g',
        'product_length_cm', 'product_height_cm', 'product_width_cm'
    ]]


def clean_translation(df: pd.DataFrame, logger: logging.Logger) -> pd.DataFrame:
    """Standardizes product category translation table."""
    logger.info("Cleaning product category translation dataset...")
    df['product_category_name'] = df['product_category_name'].astype(str).str.strip()
    df['product_category_name_english'] = df['product_category_name_english'].astype(str).str.strip().str.title()
    
    # Ensure 'sem_categoria' is mapped to 'Uncategorized'
    if not (df['product_category_name'] == 'sem_categoria').any():
        extra_row = pd.DataFrame([{
            'product_category_name': 'sem_categoria',
            'product_category_name_english': 'Uncategorized'
        }])
        df = pd.concat([df, extra_row], ignore_index=True)
        
    logger.info(f"Translations cleaned: {len(df):,} mappings.")
    return df[['product_category_name', 'product_category_name_english']]


def clean_sellers(df: pd.DataFrame, logger: logging.Logger) -> pd.DataFrame:
    """Standardizes seller states and city names."""
    logger.info("Cleaning sellers dataset...")
    df['seller_city'] = df['seller_city'].astype(str).str.strip().str.title()
    df['seller_state'] = df['seller_state'].astype(str).str.strip().str.upper()
    df['seller_zip_code_prefix'] = df['seller_zip_code_prefix'].astype(str).str.zfill(5)
    return df[['seller_id', 'seller_zip_code_prefix', 'seller_city', 'seller_state']]


def validate_referential_integrity(customers, orders, order_items, payments, products, sellers, logger):
    """Validates cross-table key consistency."""
    logger.info("Executing referential integrity validations...")
    results = {}
    
    valid_customers = set(customers['customer_id'])
    results['orphaned_orders'] = int((~orders['customer_id'].isin(valid_customers)).sum())
    
    valid_orders = set(orders['order_id'])
    results['orphaned_order_items'] = int((~order_items['order_id'].isin(valid_orders)).sum())
    
    valid_products = set(products['product_id'])
    results['orphaned_product_items'] = int((~order_items['product_id'].isin(valid_products)).sum())
    
    results['orphaned_payments'] = int((~payments['order_id'].isin(valid_orders)).sum())
    
    logger.info(f"Integrity check results: {results}")
    return results


def print_mysql_load_commands(processed_dir: Path) -> str:
    """Outputs the exact MySQL LOAD DATA commands in proper dependency order using relative/portable format."""
    normalized_path = processed_dir.as_posix()
    commands = f"""
-- ============================================================
-- MySQL High-Speed Bulk Ingestion Script
-- Run these commands in MySQL Workbench or CLI
-- ============================================================
USE ecommerce_analytics;
SET FOREIGN_KEY_CHECKS = 0;

LOAD DATA LOCAL INFILE '{normalized_path}/product_category_translation_processed.csv'
INTO TABLE product_category_translation
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE '{normalized_path}/products_processed.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE '{normalized_path}/sellers_processed.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE '{normalized_path}/customers_processed.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE '{normalized_path}/orders_processed.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE '{normalized_path}/order_items_processed.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE '{normalized_path}/order_payments_processed.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE '{normalized_path}/order_reviews_processed.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\\n'
IGNORE 1 LINES;

SET FOREIGN_KEY_CHECKS = 1;
"""
    return commands


def main():
    parser = argparse.ArgumentParser(description="Olist Brazilian E-Commerce Data Preparation Pipeline")
    parser.add_argument("--raw-dir", default=str(DEFAULT_RAW_DIR), help="Directory containing raw Olist CSVs")
    parser.add_argument("--processed-dir", default=str(DEFAULT_PROCESSED_DIR), help="Target directory for processed CSVs")
    args = parser.parse_args()

    raw_dir = Path(args.raw_dir).resolve()
    processed_dir = Path(args.processed_dir).resolve()
    processed_dir.mkdir(parents=True, exist_ok=True)

    log_file = processed_dir / "data_preparation.log"
    logger = setup_logging(log_file)
    logger.info("=== Starting Olist E-Commerce Data Cleaning & Preparation Pipeline ===")
    logger.info(f"Raw data directory:       {raw_dir}")
    logger.info(f"Processed data directory: {processed_dir}")

    files = {
        'customers': 'olist_customers_dataset.csv',
        'orders': 'olist_orders_dataset.csv',
        'order_items': 'olist_order_items_dataset.csv',
        'order_payments': 'olist_order_payments_dataset.csv',
        'order_reviews': 'olist_order_reviews_dataset.csv',
        'products': 'olist_products_dataset.csv',
        'sellers': 'olist_sellers_dataset.csv',
        'translation': 'product_category_name_translation.csv'
    }

    raw_dfs = {}
    missing_files = []
    for key, fname in files.items():
        fpath = raw_dir / fname
        if fpath.exists():
            raw_dfs[key] = load_csv(fpath, key, logger)
        else:
            missing_files.append(fname)

    if missing_files:
        logger.error(f"Missing required raw CSV files: {missing_files}")
        logger.info(f"Please ensure all CSV files exist in '{raw_dir}'")
        return 1

    # Execute cleaning pipeline
    cust_clean = clean_customers(raw_dfs['customers'], logger)
    orders_clean = clean_orders(raw_dfs['orders'], logger)
    items_clean = clean_order_items(raw_dfs['order_items'], logger)
    payments_clean, payments_agg = clean_order_payments(raw_dfs['order_payments'], logger)
    reviews_clean = clean_order_reviews(raw_dfs['order_reviews'], logger)
    products_clean = clean_products(raw_dfs['products'], logger)
    trans_clean = clean_translation(raw_dfs['translation'], logger)
    sellers_clean = clean_sellers(raw_dfs['sellers'], logger)

    # Referential integrity checks
    validate_referential_integrity(
        cust_clean, orders_clean, items_clean,
        payments_clean, products_clean, sellers_clean, logger
    )

    # Export Processed Data with UTF-8 BOM for universal Excel/PowerBI/MySQL compatibility
    logger.info("Exporting cleaned CSV files to processed directory...")
    cust_clean.to_csv(processed_dir / "customers_processed.csv", index=False, encoding='utf-8-sig')
    orders_clean.to_csv(processed_dir / "orders_processed.csv", index=False, encoding='utf-8-sig')
    items_clean.to_csv(processed_dir / "order_items_processed.csv", index=False, encoding='utf-8-sig')
    payments_clean.to_csv(processed_dir / "order_payments_processed.csv", index=False, encoding='utf-8-sig')
    payments_agg.to_csv(processed_dir / "order_payments_aggregated.csv", index=False, encoding='utf-8-sig')
    reviews_clean.to_csv(processed_dir / "order_reviews_processed.csv", index=False, encoding='utf-8-sig')
    products_clean.to_csv(processed_dir / "products_processed.csv", index=False, encoding='utf-8-sig')
    trans_clean.to_csv(processed_dir / "product_category_translation_processed.csv", index=False, encoding='utf-8-sig')
    sellers_clean.to_csv(processed_dir / "sellers_processed.csv", index=False, encoding='utf-8-sig')

    logger.info("✅ All 9 processed CSV files successfully generated.")
    
    # Save bulk load commands to SQL file
    load_sql_path = processed_dir / "mysql_bulk_load.sql"
    load_cmds = print_mysql_load_commands(processed_dir)
    with open(load_sql_path, "w", encoding="utf-8") as f:
        f.write(load_cmds)
    logger.info(f"MySQL bulk load script written to: {load_sql_path}")

    return 0


if __name__ == "__main__":
    sys.exit(main())

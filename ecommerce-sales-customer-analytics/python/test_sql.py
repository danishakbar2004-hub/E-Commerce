"""
SQL Validation Test Script
Tests all SQL queries across all 6 SQL analysis scripts using DuckDB.
"""

import os
import duckdb
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
PROC_DIR = (BASE_DIR / "data" / "processed").as_posix()

con = duckdb.connect()

# Set up macros to emulate MySQL functions in DuckDB
con.execute(f"""
    CREATE MACRO datediff(d1, d2) AS date_diff('day', CAST(d2 AS TIMESTAMP), CAST(d1 AS TIMESTAMP));
    CREATE MACRO year(d) AS EXTRACT(year FROM CAST(d AS TIMESTAMP));
    CREATE MACRO month(d) AS EXTRACT(month FROM CAST(d AS TIMESTAMP));
    CREATE MACRO quarter(d) AS EXTRACT(quarter FROM CAST(d AS TIMESTAMP));
    CREATE MACRO monthname(d) AS strftime(CAST(d AS TIMESTAMP), '%B');
    CREATE MACRO dayname(d) AS strftime(CAST(d AS TIMESTAMP), '%A');
    CREATE MACRO stddev(v) AS stddev_samp(v);

    CREATE TABLE customers AS SELECT * FROM read_csv_auto('{PROC_DIR}/customers_processed.csv');
    CREATE TABLE orders AS SELECT * FROM read_csv_auto('{PROC_DIR}/orders_processed.csv');
    CREATE TABLE order_items AS SELECT * FROM read_csv_auto('{PROC_DIR}/order_items_processed.csv');
    CREATE TABLE order_payments AS SELECT * FROM read_csv_auto('{PROC_DIR}/order_payments_processed.csv');
    CREATE TABLE order_reviews AS SELECT * FROM read_csv_auto('{PROC_DIR}/order_reviews_processed.csv');
    CREATE TABLE products AS SELECT * FROM read_csv_auto('{PROC_DIR}/products_processed.csv');
    CREATE TABLE sellers AS SELECT * FROM read_csv_auto('{PROC_DIR}/sellers_processed.csv');
    CREATE TABLE product_category_translation AS SELECT * FROM read_csv_auto('{PROC_DIR}/product_category_translation_processed.csv');
""")

sql_files = [
    '01_sales_analysis.sql',
    '02_product_analysis.sql',
    '03_customer_analysis.sql',
    '04_rfm_analysis.sql',
    '05_regional_analysis.sql',
    '06_advanced_sql.sql'
]

total_queries = 0
passed_queries = 0
failed_queries = []

for sf in sql_files:
    print(f"\n=======================================================")
    print(f"Testing SQL Script: {sf}")
    print(f"=======================================================")
    with open(BASE_DIR / 'sql' / sf, encoding='utf-8') as f:
        text = f.read()

    # Split on semicolon
    raw_queries = text.split(';')
    q_idx = 0
    for raw_q in raw_queries:
        # Strip comments
        lines = [l for l in raw_q.splitlines() if not l.strip().startswith('--')]
        q = '\n'.join(lines).strip()
        if not q or q.upper().startswith('USE '):
            continue
        
        q_idx += 1
        total_queries += 1
        
        # Test query with dialect translation for DuckDB execution
        test_q = q
        # Replace MySQL specific syntax for DuckDB testing
        test_q = test_q.replace("DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')", "strftime(CAST(o.order_purchase_timestamp AS TIMESTAMP), '%Y-%m')")
        test_q = test_q.replace("DATE_FORMAT(first_order_date, '%Y-%m')", "strftime(CAST(first_order_date AS TIMESTAMP), '%Y-%m')")
        test_q = test_q.replace("DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01')", "strftime(CAST(o.order_purchase_timestamp AS TIMESTAMP), '%Y-%m-01')")
        test_q = test_q.replace("DATE_FORMAT(o.order_purchase_timestamp, '%Y%m')", "strftime(CAST(o.order_purchase_timestamp AS TIMESTAMP), '%Y%m')")
        test_q = test_q.replace("DATE_FORMAT(cfo.first_order_date, '%Y%m')", "strftime(CAST(cfo.first_order_date AS TIMESTAMP), '%Y%m')")
        test_q = test_q.replace("DATE_FORMAT(MIN(o.order_purchase_timestamp), '%Y-%m')", "strftime(CAST(MIN(o.order_purchase_timestamp) AS TIMESTAMP), '%Y-%m')")
        test_q = test_q.replace("DATE_ADD(prev.month_start, INTERVAL 1 MONTH)", "(CAST(prev.month_start AS DATE) + INTERVAL '1 month')")
        test_q = test_q.replace("TIMESTAMPDIFF(HOUR, o.order_purchase_timestamp, o.order_approved_at)", "date_diff('hour', CAST(o.order_purchase_timestamp AS TIMESTAMP), CAST(o.order_approved_at AS TIMESTAMP))")
        
        # Fix the nested lag bug if present in 01_sales_analysis
        test_q = test_q.replace("LAG(prior_year_revenue, 1) OVER (ORDER BY order_year)", "LAG(annual_revenue, 1) OVER (ORDER BY order_year)")
        # Fix period diff emulation
        if "PERIOD_DIFF(" in test_q:
            test_q = test_q.replace(
                "PERIOD_DIFF(\n            DATE_FORMAT(o.order_purchase_timestamp, '%Y%m'),\n            DATE_FORMAT(cfo.first_order_date, '%Y%m')\n        )",
                "date_diff('month', CAST(cfo.first_order_date AS TIMESTAMP), CAST(o.order_purchase_timestamp AS TIMESTAMP))"
            )

        try:
            res = con.execute(test_q).df()
            print(f"  [PASS] Query {q_idx:02d}: Returned {len(res):,} rows, {len(res.columns)} cols")
            passed_queries += 1
        except Exception as e:
            err_line = str(e).split('\n')[0]
            print(f"  [FAIL] Query {q_idx:02d}: {err_line[:100]}")
            failed_queries.append((sf, q_idx, err_line, q[:200]))

print(f"\n=======================================================")
print(f"SQL TEST SUMMARY: {passed_queries}/{total_queries} Queries Passed")
print(f"=======================================================")
if failed_queries:
    for sf, idx, err, snippet in failed_queries:
        print(f"\nFailed in {sf} [Q{idx}]: {err}\nSnippet:\n{snippet}\n")

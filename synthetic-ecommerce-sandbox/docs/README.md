# E-Commerce Sales & Customer Analytics Dashboard
### A complete, portfolio-ready data analytics project

---

## Project Overview

This project demonstrates an end-to-end data analytics pipeline for an e-commerce business — from raw database design through SQL analysis to interactive Power BI dashboards and formatted Excel reports.

**Business Questions Answered:**
- Why are sales changing month over month?
- Which products and categories generate the most revenue?
- Who are our most valuable customers?
- Which regions are growing fastest?
- Which customers are at risk of churning?

---

## Project Structure

```
E-Commerce/
├── sql/
│   ├── schema/
│   │   ├── 01_create_tables.sql           ← MySQL schema
│   │   └── 02_create_tables_postgresql.sql ← PostgreSQL schema
│   ├── sample_data/
│   │   ├── 01_seed_regions_customers.sql  ← 10 regions, 100 customers, 50 products
│   │   ├── 02_seed_orders.sql             ← ~155 orders (2022–2024)
│   │   └── 03_seed_order_items.sql        ← Order line items
│   └── queries/
│       ├── 01_revenue_and_sales_trends.sql
│       ├── 02_product_performance.sql
│       ├── 03_customer_analytics.sql
│       ├── 04_rfm_analysis.sql
│       ├── 05_regional_analysis.sql
│       ├── 06_advanced_analytics.sql
│       └── 07_powerbi_views.sql
│
├── powerbi/
│   ├── dax_measures/
│   │   ├── 01_core_measures.dax           ← Revenue, Time Intelligence, KPIs
│   │   ├── 02_product_measures.dax        ← Product & category analysis
│   │   ├── 03_customer_measures.dax       ← CLV, RFM, cohort measures
│   │   └── 04_regional_measures.dax       ← Regional, map, shipping measures
│   └── setup_guide/
│       └── POWERBI_SETUP_GUIDE.md         ← Full setup instructions
│
├── excel/
│   ├── generate_excel.py                  ← Python script to create Excel files
│   ├── 01_Monthly_Sales_Trends.xlsx       ← Generated ✔
│   ├── 02_Product_Performance.xlsx        ← Generated ✔
│   ├── 03_Customer_RFM_Analysis.xlsx      ← Generated ✔
│   └── 04_Regional_Analysis.xlsx          ← Generated ✔
│
└── docs/
    └── README.md                          ← This file
```

---

## Database Schema

```
regions ──────────────────────────────────────────────────────┐
                                                              │
customers ─────────────────────────────────────────┐         │
                                                   │         │
                              orders ◄─────────────┘    ◄───┘
                                │
                           order_items
                                │
                           products ──► categories
```

### Entity-Relationship Summary

| Table | Rows | Description |
|---|---|---|
| `regions` | 10 | Geographic regions across USA, UK, Canada, Australia |
| `customers` | 100 | Customer profiles with region assignment |
| `categories` | 24 | 7 top-level + 17 sub-categories |
| `products` | 50 | Real-world product names across all categories |
| `orders` | ~155 | Orders from Jan 2022 – Oct 2024 |
| `order_items` | ~280 | Line items linking orders to products |

---

## SQL Concepts Demonstrated

| Concept | Query File | Example |
|---|---|---|
| **JOINs** (INNER, LEFT) | All files | Joining orders → items → products → categories |
| **GROUP BY + HAVING** | `02`, `03` | Revenue by category, customers with 2+ orders |
| **CTEs** | All files | Multi-step RFM calculation, cohort analysis |
| **Subqueries** | `02`, `06` | Order status funnel, product co-purchase |
| **Window Functions** | `01`, `06` | LAG, LEAD, RANK, NTILE, SUM OVER, running totals |
| **CASE Statements** | `03`, `04` | RFM segments, customer segments, velocity |
| **Date Functions** | `01`, `03`, `05` | DATEDIFF, DATE_FORMAT, YEAR, QUARTER, MONTH |
| **Self-JOIN** | `06` | Basket/co-purchase analysis |
| **Recursive CTE** | `07` | Date dimension spine generation |

---

## Analytics Delivered

### Revenue & Sales Trends (`01_revenue_and_sales_trends.sql`)
- ✅ Total revenue (gross + net)
- ✅ Monthly sales trends with running cumulative
- ✅ Yearly revenue summary
- ✅ Month-over-month growth % with trend indicator
- ✅ Quarterly breakdown
- ✅ Average Order Value (AOV) by month

### Product Performance (`02_product_performance.sql`)
- ✅ Top 10 products by revenue with profit margin
- ✅ Best-performing categories with revenue share %
- ✅ Product ranking (revenue, profit, volume) using window functions
- ✅ Slow-moving vs fast-moving product classification
- ✅ Monthly top-5 products per period

### Customer Analytics (`03_customer_analytics.sql`)
- ✅ Customer purchase frequency with segmentation
- ✅ Repeat customer rate
- ✅ Customer Lifetime Value (CLV) with ranking
- ✅ New vs returning customers per month
- ✅ Value-based customer segmentation (VIP Champion → At Risk)
- ✅ Cohort retention analysis (12-month)

### RFM Analysis (`04_rfm_analysis.sql`)
- ✅ Recency, Frequency, Monetary raw values per customer
- ✅ NTILE-based 1–5 scoring for each dimension
- ✅ 9-segment RFM classification
- ✅ Segment summary with revenue contribution
- ✅ Marketing action recommendations per segment

### Regional Analysis (`05_regional_analysis.sql`)
- ✅ Revenue by region with share % and rank
- ✅ Regional monthly trends with MoM growth
- ✅ Country-level summary
- ✅ Best-selling categories per region
- ✅ Shipping performance and cancellation rates

### Advanced Analytics (`06_advanced_analytics.sql`)
- ✅ Running totals, 3-month & 6-month rolling averages
- ✅ Year-over-year comparison
- ✅ Basket/co-purchase analysis (self-JOIN)
- ✅ Customer acquisition trend
- ✅ Order status funnel
- ✅ Discount impact analysis
- ✅ Reorder interval distribution
- ✅ Multi-window percent contribution analysis

---

## Power BI Dashboards

### Page 1: Executive Sales Overview
KPI cards (Revenue, Orders, AOV, MoM Growth) + Revenue trend line + Status donut + Regional bar + Monthly matrix

### Page 2: Product Performance Dashboard
Top-10 horizontal bar + Category treemap + Margin scatter plot + Revenue vs prior year line + Full product table with rankings

### Page 3: Customer Behaviour Dashboard
RFM bubble chart + Segment donut + CLV histogram + Cohort retention matrix (heat-map style) + New vs returning stacked bar + Top-10 customers table

### Page 4: Regional Sales Analysis
Filled map by country + Regional bar chart + AOV comparison + Category-region matrix + Shipping KPIs

### DAX Measures Coverage

| Category | Measures |
|---|---|
| Core Revenue | Total Gross/Net Revenue, AOV, Avg Revenue/Customer |
| Profit | Gross Profit, Margin %, COGS |
| Time Intelligence | MoM, YoY, YTD, QTD, MTD, Rolling 3M/12M |
| Product | Revenue Rank, Category Share, Stock metrics |
| Customer | CLV, Repeat Rate, Churn Rate, New Customers |
| RFM | Segment Revenue, Champions %, Avg RFM Score |
| Regional | Region Rank, MoM Growth, Map bubble size, Tooltip |

---

## Excel Reports (Pre-built)

| File | Sheets | Key Features |
|---|---|---|
| `01_Monthly_Sales_Trends.xlsx` | Trends + Chart | Colour scale on revenue, line chart |
| `02_Product_Performance.xlsx` | Products + Chart | Data bars, medal emojis for top 3, bar chart |
| `03_Customer_RFM_Analysis.xlsx` | RFM + Summary | Segment colour-coding, summary pivot |
| `04_Regional_Analysis.xlsx` | Regions + Chart | Conditional MoM colours, pie chart |

---

## Quick Start

### 1. Set Up the Database (MySQL)
```bash
mysql -u root -p < sql/schema/01_create_tables.sql
mysql -u root -p ecommerce_db < sql/sample_data/01_seed_regions_customers.sql
mysql -u root -p ecommerce_db < sql/sample_data/02_seed_orders.sql
mysql -u root -p ecommerce_db < sql/sample_data/03_seed_order_items.sql
mysql -u root -p ecommerce_db < sql/queries/07_powerbi_views.sql
```

### 2. Set Up the Database (PostgreSQL)
```bash
psql -U postgres -c "CREATE DATABASE ecommerce_db;"
psql -U postgres -d ecommerce_db -f sql/schema/02_create_tables_postgresql.sql
psql -U postgres -d ecommerce_db -f sql/sample_data/01_seed_regions_customers.sql
psql -U postgres -d ecommerce_db -f sql/sample_data/02_seed_orders.sql
psql -U postgres -d ecommerce_db -f sql/sample_data/03_seed_order_items.sql
```

### 3. Run SQL Analytics
Open any file in `sql/queries/` in MySQL Workbench, DBeaver, or pgAdmin and execute.

### 4. Connect Power BI
Follow `powerbi/setup_guide/POWERBI_SETUP_GUIDE.md`

### 5. Generate Excel Reports
```bash
pip install openpyxl
python excel/generate_excel.py
```

---

## Skills Demonstrated

**SQL:**
JOINs • CTEs • Window Functions (LAG, RANK, NTILE, SUM OVER) • Subqueries • GROUP BY/HAVING • CASE • Date Functions • Recursive CTEs • Views • Self-JOINs

**Power BI:**
Data Modelling (Star Schema) • DAX Measures • Time Intelligence • Power Query (M) • Conditional Formatting • Drill-through • Tooltips • Interactive Slicers • KPI Cards • Map Visuals

**Excel:**
Structured Tables • Conditional Formatting (Colour Scales, Data Bars) • Charts (Line, Bar, Pie) • Python/openpyxl for programmatic generation

**Analytics Concepts:**
RFM Analysis • Customer Lifetime Value • Cohort Retention • Basket Analysis • MoM/YoY Growth • Running Totals • Rolling Averages • Customer Segmentation

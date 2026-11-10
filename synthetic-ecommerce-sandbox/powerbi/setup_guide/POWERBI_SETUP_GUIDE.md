# Power BI Setup Guide
## E-Commerce Sales & Customer Analytics Dashboard

---

## 1. Prerequisites

| Requirement | Details |
|---|---|
| Power BI Desktop | Latest version (free download from Microsoft) |
| Database | MySQL 8.0+ or PostgreSQL 13+ with schema loaded |
| ODBC Driver | MySQL ODBC 8.0 Connector **or** npgsql for PostgreSQL |
| Data | All seed SQL scripts executed |

---

## 2. Database Connection

### Step 1 — Connect Power BI to MySQL
1. Open Power BI Desktop → **Get Data** → **MySQL database**
2. Enter your server (`localhost` or IP) and database name (`ecommerce_db`)
3. Use **DirectQuery** mode for live data, or **Import** for better performance
4. When prompted, enter your MySQL username & password

### Step 2 — Connect to PostgreSQL
1. **Get Data** → **PostgreSQL database**
2. Enter server and database, then **Import** mode

---

## 3. Data Model & Relationships

After importing the following tables/views, set up relationships in **Model view**:

### Tables to Import
```
vw_fact_sales        → Main fact table
vw_dim_customers     → Customer dimension
vw_dim_products      → Product dimension
vw_dim_date          → Date dimension  (or create in DAX)
vw_rfm_segments      → RFM customer segments
regions              → Region dimension
orders               → For cancellation & status metrics
```

### Relationship Setup (Star Schema)

```
         vw_dim_date
              │ date ↕ order_date
              │
vw_dim_customers ──customer_id──► vw_fact_sales ◄──product_id── vw_dim_products
                                        │
                                   region_id
                                        │
                                     regions
```

| From Table | From Column | To Table | To Column | Cardinality |
|---|---|---|---|---|
| `vw_fact_sales` | `order_date` | `vw_dim_date` | `date` | Many-to-One |
| `vw_fact_sales` | `customer_id` | `vw_dim_customers` | `customer_id` | Many-to-One |
| `vw_fact_sales` | `product_id` | `vw_dim_products` | `product_id` | Many-to-One |
| `vw_fact_sales` | `region_id` | `regions` | `region_id` | Many-to-One |
| `vw_rfm_segments` | `customer_id` | `vw_dim_customers` | `customer_id` | One-to-One |

> **Tip:** Mark `vw_dim_date` as the **Date Table** (right-click → Mark as date table → select `date` column).

---

## 4. Create Date Dimension in DAX (Recommended)

Instead of importing `vw_dim_date`, create it in Power BI with:

```dax
dim_date =
VAR MinDate = DATE(2022, 1, 1)
VAR MaxDate = DATE(2025, 12, 31)
RETURN
ADDCOLUMNS(
    CALENDAR(MinDate, MaxDate),
    "Year",         YEAR([Date]),
    "Quarter",      QUARTER([Date]),
    "Quarter Label",FORMAT([Date], "\QQ"),
    "Month Number", MONTH([Date]),
    "Month Name",   FORMAT([Date], "MMMM"),
    "Month Short",  FORMAT([Date], "MMM"),
    "Month Year",   FORMAT([Date], "MMM YYYY"),
    "Day",          DAY([Date]),
    "Day Name",     FORMAT([Date], "dddd"),
    "Day Short",    FORMAT([Date], "ddd"),
    "Week Number",  WEEKNUM([Date]),
    "Is Weekend",   IF(WEEKDAY([Date], 2) >= 6, TRUE, FALSE),
    "Year Month",   FORMAT([Date], "YYYY-MM"),
    "Year Quarter", YEAR([Date]) & "-Q" & QUARTER([Date])
)
```

---

## 5. Power Query Transformations

Apply these transformations in **Power Query Editor** (Transform Data):

### For `vw_fact_sales`
```m
// 1. Change order_date to Date/Time type
// 2. Add a calculated column: revenue_category
= Table.AddColumn(Source, "Revenue Category",
    each if [net_line_value] >= 1000 then "High Value"
         else if [net_line_value] >= 200 then "Mid Value"
         else "Low Value")

// 3. Filter out test/cancelled orders (optional)
= Table.SelectRows(Source, each [order_status] = "Delivered")
```

### For `vw_rfm_segments`
```m
// Add RFM Colour for conditional formatting
= Table.AddColumn(Source, "Segment Color",
    each if [rfm_segment] = "Champions" then "#2ECC71"
         else if [rfm_segment] = "Loyal Customers" then "#27AE60"
         else if [rfm_segment] = "At Risk" then "#E74C3C"
         else if [rfm_segment] = "Lost" then "#95A5A6"
         else "#3498DB")
```

---

## 6. Report Pages & Visuals

### Page 1: Executive Sales Overview

| Visual | Type | Fields |
|---|---|---|
| Total Revenue KPI | Card | `Total Net Revenue` |
| Total Orders KPI | Card | `Total Orders` |
| AOV KPI | Card | `Average Order Value` |
| MoM Growth KPI | Card | `MoM Revenue Growth %` |
| Revenue Trend | Line Chart | X: `Month Year`, Y: `Total Net Revenue`, Secondary: `MoM Revenue Growth %` |
| Revenue by Status | Donut Chart | Category: `order_status`, Values: `Total Orders` |
| Monthly Orders Table | Matrix | Rows: `Year`, Columns: `Month Short`, Values: `Total Orders`, `Total Net Revenue` |
| Top Regions Bar | Clustered Bar | Y: `region_name`, X: `Total Net Revenue` |

**Slicers:** Year, Quarter, Region, Country

---

### Page 2: Product Performance Dashboard

| Visual | Type | Fields |
|---|---|---|
| Top 10 Products | Horizontal Bar | Y: `product_name`, X: `Total Net Revenue` (top N filter = 10) |
| Category Revenue | Treemap | Group: `category_name`, Values: `Total Net Revenue` |
| Category Comparison | Clustered Column | X: `category_name`, Y: `Total Net Revenue` + `Total Gross Profit` |
| Margin Analysis | Scatter Plot | X: `Total Net Revenue`, Y: `Product Margin %`, Size: `Total Units Sold` |
| Product Table | Table | `product_name`, `category_name`, `Total Units Sold`, `Total Net Revenue`, `Product Margin %`, `Product Revenue Rank` |
| Revenue vs Prior Year | Line Chart | X: `Month Year`, Lines: `Total Net Revenue` + `Revenue SPLY` |

**Slicers:** Category, Year, Date Range

**Drill-through:** From any product → product detail page

---

### Page 3: Customer Behaviour Dashboard

| Visual | Type | Fields |
|---|---|---|
| Total Customers KPI | Card | `Total Customers` |
| Repeat Rate KPI | Card | `Repeat Customer Rate %` |
| Avg CLV KPI | Card | `Average CLV` |
| Avg Order Value KPI | Card | `Average Order Value` |
| RFM Segment Bubble | Scatter Plot | X: `Avg Recency Days`, Y: `Avg Purchase Frequency`, Size: `Average CLV`, Color: `rfm_segment` |
| Segment Distribution | Donut | Category: `rfm_segment`, Values: `RFM Segment Customers` |
| CLV Histogram | Column | X: Binned `lifetime_value`, Y: `Total Customers` |
| Cohort Retention | Matrix | Rows: `cohort_month`, Columns: `month_number`, Values: `retention_pct` (colour-coded) |
| New vs Returning | Stacked Bar | X: `Month Year`, Stacked: `New Customers` + `Returning Customers` |
| Top 10 Customers | Table | `customer_name`, `total_orders`, `lifetime_value`, `rfm_segment`, `days_since_last_order` |

**Slicers:** RFM Segment, Region, Year, Date Range

---

### Page 4: Regional Sales Analysis

| Visual | Type | Fields |
|---|---|---|
| Revenue by Country | Filled Map | Location: `country`, Values: `Total Net Revenue` |
| Revenue by Region | Clustered Bar | Y: `region_name`, X: `Total Net Revenue` |
| Regional AOV | Column | X: `region_name`, Y: `Region AOV` |
| Country Comparison | Table | `country`, `Total Orders`, `Total Customers`, `Total Net Revenue`, `Region AOV`, `Region MoM Growth %` |
| Region Trend | Line Chart | X: `Month Year`, Lines: each region (small multiples) |
| Top Category/Region | Matrix | Rows: `region_name`, Columns: `category_name`, Values: `Total Net Revenue` |
| Shipping KPIs | Card | `Avg Days to Ship`, `On-Time Delivery Rate %`, `Region Cancellation Rate %` |

**Slicers:** Country, Region, Year, Month

---

## 7. Formatting & Design Tips

### KPI Cards
- Use **conditional formatting** on card values
- Green = positive growth (>0%), Red = negative
- Font: Segoe UI, 28pt for numbers, 12pt for labels

### Colour Palette
```
Primary Blue:    #0078D4   (Microsoft blue)
Success Green:   #2ECC71
Warning Orange:  #F39C12
Danger Red:      #E74C3C
Neutral Grey:    #95A5A6
Background:      #F8F9FA
```

### Tooltips
- Create a **tooltip page** (Page info → Tooltip = ON, set to 400×250 px)
- Add mini sparkline + product detail for product visuals
- Enable on each visual: Format → Tooltip → Report page → select your tooltip page

### Interactive Slicers
- Add a "Clear All Slicers" button with bookmark action
- Use **Sync Slicers** so Year/Date slicers work across all pages
- Use **Hierarchy slicers** for Year > Quarter > Month

---

## 8. Publish & Share

1. **File → Publish → Power BI Service**
2. Set up **Scheduled Refresh** (if using Import mode):
   - Go to dataset settings in Power BI Service
   - Set refresh frequency: Daily at 7:00 AM
3. Create a **Dashboard** by pinning key visuals from each report page
4. Set up **Email Subscriptions** for stakeholders

---

## 9. Performance Optimisation

- Use **Import mode** instead of DirectQuery for better performance
- Create **aggregation tables** for large datasets
- Use `DIVIDE()` instead of `/` to handle divide-by-zero
- Avoid calculated columns — prefer measures
- Use **Incremental Refresh** when data exceeds 1M rows
- Disable Auto Date/Time for custom date tables

# Power BI DAX Measures Reference Suite
## E-Commerce Sales & Customer Analytics Platform (Olist Dataset)

This repository contains the definitive catalog of DAX business measures for the 4-page Power BI executive dashboard. All measures adhere to the project's standardized revenue definition: **Gross Item Revenue on Delivered Orders** to ensure strict reconciliation against underlying MySQL analytical queries.

---

### Table of Contents
1. [Date Dimension Setup](#1-date-dimension-setup)
2. [Executive Sales & Revenue Measures](#2-executive-sales--revenue-measures)
3. [Time Intelligence Measures](#3-time-intelligence-measures)
4. [Product & Category Performance Measures](#4-product--category-performance-measures)
5. [Customer Analytics & Retention Measures](#5-customer-analytics--retention-measures)
6. [RFM Segmentation Measures](#6-rfm-segmentation-measures)
7. [Regional & Logistics Measures](#7-regional--logistics-measures)

---

### 1. Date Dimension Setup

Create this table in Power BI via **Modeling -> New Table**:

```dax
Dim_Date = 
VAR MinDate = DATE(2016, 1, 1)
VAR MaxDate = DATE(2018, 12, 31)
RETURN
ADDCOLUMNS(
    CALENDAR(MinDate, MaxDate),
    "Year", YEAR([Date]),
    "Month Number", MONTH([Date]),
    "Month Name", FORMAT([Date], "MMMM"),
    "Month Short", FORMAT([Date], "MMM"),
    "Year-Month", FORMAT([Date], "YYYY-MM"),
    "Month-Year Label", FORMAT([Date], "MMM YYYY"),
    "Quarter", "Q" & FORMAT([Date], "Q"),
    "Year-Quarter", YEAR([Date]) & "-Q" & FORMAT([Date], "Q"),
    "Day of Week Number", WEEKDAY([Date], 2), -- 1 = Monday, 7 = Sunday
    "Day of Week Name", FORMAT([Date], "dddd"),
    "Is Weekend", IF(WEEKDAY([Date], 2) >= 6, TRUE, FALSE),
    "Week Number", WEEKNUM([Date], 2)
)
```

> **Configuration Note:** Right-click `Dim_Date` in the model view and select **Mark as Date Table**, setting `[Date]` as the primary key. Sort `[Month-Year Label]` by `[Year-Month]`.

---

### 2. Executive Sales & Revenue Measures

#### Total Revenue
```dax
Total Revenue = 
CALCULATE(
    SUM(order_items[price]),
    orders[order_status] = "delivered"
)
```

#### Total Delivered Orders
```dax
Total Delivered Orders = 
CALCULATE(
    DISTINCTCOUNT(orders[order_id]),
    orders[order_status] = "delivered"
)
```

#### Total Unique Customers
```dax
Total Unique Customers = 
CALCULATE(
    DISTINCTCOUNT(customers[customer_unique_id]),
    orders[order_status] = "delivered"
)
```

#### Average Order Value (AOV)
```dax
Average Order Value = 
DIVIDE(
    [Total Revenue],
    [Total Delivered Orders],
    0
)
```

#### Total Freight Revenue
```dax
Total Freight Revenue = 
CALCULATE(
    SUM(order_items[freight_value]),
    orders[order_status] = "delivered"
)
```

#### Total Gross Merchandise Value (GMV)
```dax
Total GMV = 
[Total Revenue] + [Total Freight Revenue]
```

---

### 3. Time Intelligence Measures

#### Revenue Previous Month (PM)
```dax
Revenue Previous Month = 
CALCULATE(
    [Total Revenue],
    PREVIOUSMONTH(Dim_Date[Date])
)
```

#### Month-over-Month Revenue Growth %
```dax
MoM Revenue Growth % = 
VAR CurrentRevenue = [Total Revenue]
VAR PriorRevenue   = [Revenue Previous Month]
RETURN
DIVIDE(
    CurrentRevenue - PriorRevenue,
    PriorRevenue,
    BLANK()
)
```

#### Revenue Previous Year (SPLY)
```dax
Revenue Previous Year = 
CALCULATE(
    [Total Revenue],
    SAMEPERIODLASTYEAR(Dim_Date[Date])
)
```

#### Year-over-Year (YoY) Revenue Growth %
```dax
YoY Revenue Growth % = 
DIVIDE(
    [Total Revenue] - [Revenue Previous Year],
    [Revenue Previous Year],
    BLANK()
)
```

#### Revenue YTD (Year-to-Date)
```dax
Revenue YTD = 
TOTALYTD(
    [Total Revenue],
    Dim_Date[Date]
)
```

#### Rolling 3-Month Revenue
```dax
Rolling 3M Revenue = 
CALCULATE(
    [Total Revenue],
    DATESINPERIOD(
        Dim_Date[Date],
        LASTDATE(Dim_Date[Date]),
        -3,
        MONTH
    )
)
```

#### MoM Trend Indicator Icon
```dax
MoM Trend Icon = 
SWITCH(
    TRUE(),
    ISBLANK([MoM Revenue Growth %]), "-",
    [MoM Revenue Growth %] >= 0.10, "▲▲ Accelerating",
    [MoM Revenue Growth %] > 0, "▲ Growing",
    [MoM Revenue Growth %] = 0, "→ Stable",
    [MoM Revenue Growth %] > -0.10, "▼ Declining",
    "▼▼ Contracting"
)
```

---

### 4. Product & Category Performance Measures

#### Units Sold
```dax
Units Sold = 
CALCULATE(
    COUNT(order_items[order_item_id]),
    orders[order_status] = "delivered"
)
```

#### Category Revenue Share %
```dax
Category Revenue Share % = 
DIVIDE(
    [Total Revenue],
    CALCULATE(
        [Total Revenue],
        ALL(product_category_translation[product_category_name_english])
    ),
    0
)
```

#### Product Revenue Rank
```dax
Product Revenue Rank = 
RANKX(
    ALL(products[product_id]),
    [Total Revenue],
    ,
    DESC,
    DENSE
)
```

#### Average Selling Price per Unit
```dax
Avg Selling Price = 
DIVIDE(
    [Total Revenue],
    [Units Sold],
    0
)
```

---

### 5. Customer Analytics & Retention Measures

#### Repeat Customers Count
```dax
Repeat Customers = 
CALCULATE(
    DISTINCTCOUNT(customers[customer_unique_id]),
    FILTER(
        VALUES(customers[customer_unique_id]),
        CALCULATE(DISTINCTCOUNT(orders[order_id]), orders[order_status] = "delivered") > 1
    )
)
```

#### Repeat Customer Rate %
```dax
Repeat Customer Rate % = 
DIVIDE(
    [Repeat Customers],
    [Total Unique Customers],
    0
)
```

#### One-Time Customers Count
```dax
One-Time Customers = 
[Total Unique Customers] - [Repeat Customers]
```

#### Revenue from Repeat Customers
```dax
Repeat Customer Revenue = 
CALCULATE(
    [Total Revenue],
    FILTER(
        VALUES(customers[customer_unique_id]),
        CALCULATE(DISTINCTCOUNT(orders[order_id]), orders[order_status] = "delivered") > 1
    )
)
```

#### Repeat Customer Revenue Share %
```dax
Repeat Revenue Share % = 
DIVIDE(
    [Repeat Customer Revenue],
    [Total Revenue],
    0
)
```

---

### 6. RFM Segmentation Measures

#### Reference Analysis Date (Constant)
```dax
RFM Reference Date = DATE(2018, 10, 17)
```

#### Customer Recency in Days
```dax
Customer Recency Days = 
VAR LatestPurchase = MAX(orders[order_purchase_timestamp])
RETURN
IF(
    NOT ISBLANK(LatestPurchase),
    DATEDIFF(LatestPurchase, [RFM Reference Date], DAY),
    BLANK()
)
```

#### Champions Revenue Contribution %
```dax
Champions Revenue % = 
VAR ChampRevenue = 
    CALCULATE(
        [Total Revenue],
        FILTER(
            customers,
            RELATED(rfm_segments[customer_segment]) = "Champions"
        )
    )
RETURN
DIVIDE(ChampRevenue, [Total Revenue], 0)
```

---

### 7. Regional & Logistics Measures

#### State Revenue Share %
```dax
State Revenue Share % = 
DIVIDE(
    [Total Revenue],
    CALCULATE([Total Revenue], ALL(customers[customer_state])),
    0
)
```

#### Average Actual Delivery Days
```dax
Avg Actual Delivery Days = 
AVERAGEX(
    FILTER(orders, orders[order_status] = "delivered" && NOT ISBLANK(orders[order_delivered_customer_date])),
    DATEDIFF(orders[order_purchase_timestamp], orders[order_delivered_customer_date], DAY)
)
```

#### On-Time Delivery Rate %
```dax
On-Time Delivery Rate % = 
VAR OnTimeOrders = 
    CALCULATE(
        COUNTROWS(orders),
        orders[order_status] = "delivered",
        orders[order_delivered_customer_date] <= orders[order_estimated_delivery_date]
    )
VAR DeliveredOrders = 
    CALCULATE(
        COUNTROWS(orders),
        orders[order_status] = "delivered",
        NOT ISBLANK(orders[order_delivered_customer_date])
    )
RETURN
DIVIDE(OnTimeOrders, DeliveredOrders, 0)
```

#### Average Customer Review Rating
```dax
Avg Review Score = 
AVERAGE(order_reviews[review_score])
```

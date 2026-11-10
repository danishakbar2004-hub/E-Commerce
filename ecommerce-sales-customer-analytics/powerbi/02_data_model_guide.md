# Power BI Data Architecture & Star Schema Guide
## E-Commerce Sales & Customer Analytics Platform

---

### 1. Conceptual Architecture & Star Schema

The analytical model is structured around a **Central Fact Table** (`order_items`) joined outward to core dimensions. This avoids many-to-many ambiguity, eliminates circular dependencies, and guarantees optimal VertiPaq engine compression.

```
                              [Dim_Date]
                                  │ (1:*)
                                  ▼
[Dim_Customers] (1:*) ──► [Dim_Orders] (1:*) ──► [Fact_Order_Items] ◄── (1:*) [Dim_Products]
                                  │                       ▲                      │ (1:*)
                                  │ (1:1)                 │ (1:*)                ▼
                                  ▼                       │            [Dim_Category_Translation]
                       [Dim_Order_Reviews]        [Dim_Sellers]
                                  │
                                  ▼
                   [Fact_Order_Payments_Agg] (1:1 on order_id)
```

---

### 2. Table Relationships & Cardinality Matrix

| From Table (Dimension) | Key Column | To Table (Fact / Bridge) | Foreign Key Column | Cardinality | Cross-Filter Direction | Active |
|---|---|---|---|---|---|---|
| `Dim_Date` | `Date` | `orders` | `order_purchase_timestamp` | 1 to Many (`1:*`) | Single (`Dim_Date` filters `orders`) | Yes |
| `customers` | `customer_id` | `orders` | `customer_id` | 1 to Many (`1:*`) | Single (`customers` filters `orders`) | Yes |
| `orders` | `order_id` | `order_items` | `order_id` | 1 to Many (`1:*`) | Single (`orders` filters `order_items`) | Yes |
| `products` | `product_id` | `order_items` | `product_id` | 1 to Many (`1:*`) | Single (`products` filters `order_items`) | Yes |
| `product_category_translation` | `product_category_name` | `products` | `product_category_name` | 1 to Many (`1:*`) | Single (`translation` filters `products`) | Yes |
| `sellers` | `seller_id` | `order_items` | `seller_id` | 1 to Many (`1:*`) | Single (`sellers` filters `order_items`) | Yes |
| `orders` | `order_id` | `order_reviews` | `order_id` | 1 to 1 (`1:1`) | Single (`orders` filters `order_reviews`) | Yes |
| `orders` | `order_id` | `order_payments_aggregated` | `order_id` | 1 to 1 (`1:1`) | Single (`orders` filters `payments`) | Yes |

> ⚠️ **CRITICAL MODELLING WARNING: Never join `order_payments` directly to `order_items`**  
> In Olist, orders frequently contain both multiple items (e.g. 3 items) and split payment methods (e.g. Voucher + Credit Card = 2 payment rows). Directly joining `order_items` to `order_payments` creates an unintended cartesian product (6 rows instead of 3), duplicating recorded revenue by 200%.  
> Always use `order_payments_aggregated` (grouped by `order_id`) or model payments through the `orders` header.

---

### 3. Power Query (M) Transformation Steps

When importing raw or processed data via **Power Query**, apply the following transformations:

#### A. Orders Table
```powerquery
let
    Source = Csv.Document(File.Contents(".../orders_processed.csv"), [Delimiter=",", Columns=9, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{
        {"order_id", type text},
        {"customer_id", type text},
        {"order_status", type text},
        {"order_purchase_timestamp", type datetime},
        {"order_approved_at", type datetime},
        {"order_delivered_carrier_date", type datetime},
        {"order_delivered_customer_date", type datetime},
        {"order_estimated_delivery_date", type datetime}
    }),
    #"Added Delivery Days" = Table.AddColumn(#"Changed Type", "Delivery_Duration_Days", 
        each Duration.Days([order_delivered_customer_date] - [order_purchase_timestamp]), Int64.Type)
in
    #"Added Delivery Days"
```

#### B. Products Table with Category Translation
```powerquery
let
    Source = Csv.Document(File.Contents(".../products_processed.csv"), [Delimiter=",", Encoding=65001]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Merged Translation" = Table.NestedJoin(#"Promoted Headers", {"product_category_name"}, product_category_translation, {"product_category_name"}, "Trans", JoinKind.LeftOuter),
    #"Expanded Trans" = Table.ExpandTableColumn(#"Merged Translation", "Trans", {"product_category_name_english"}, {"Category_English"}),
    #"Replaced Nulls" = Table.ReplaceValue(#"Expanded Trans", null, "Uncategorized", Replacer.ReplaceValue, {"Category_English"})
in
    #"Replaced Nulls"
```

---

### 4. Direct Lake & VertiPaq Performance Optimization
1. **Integer Keys over Strings:** If loading massive data, substitute 32-character MD5 strings (`order_id`, `product_id`) with 64-bit integer surrogate keys generated during ETL.
2. **Hide Foreign Keys:** Hide all foreign key columns in fact tables from report view; expose only dimension attributes to dashboard authors.
3. **Format Strings:** Explicitly apply Currency format (`$#,##0.00` or `R$ #,##0.00`) to monetary measures, and Percentage format (`0.0%`) to ratios.

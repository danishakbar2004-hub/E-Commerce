# Power BI Dashboard Visual Specifications
## Corporate BI Design Standards: E-Commerce Executive Platform

---

### Dashboard Global Specifications
- **Canvas Resolution:** 1280 x 720 (16:9 widescreen)
- **Palette (Corporate Light Theme):**
  - Primary Slate: `#1E293B`
  - Accent Cobalt: `#0078D4`
  - Positive KPI Green: `#10B981`
  - Warning Orange: `#F59E0B`
  - Negative Alert Red: `#EF4444`
  - Neutral Background: `#F8FAFC`
  - Card Fill Background: `#FFFFFF` with 1px border `#E2E8F0`
- **Typography:** Segoe UI (Headers: 14pt Semi-bold; Data Values: 24pt Bold; Labels: 9pt Regular)

---

### PAGE 1: Executive Sales Overview

#### Top Header & Slicer Bar (Y: 10px to 80px)
- **Title Block:** "E-Commerce Executive Sales Performance Overview" (18pt Bold, `#1E293B`)
- **Global Slicers:**
  - `Dim_Date[Year]` (Dropdown or Tile selection: 2016, 2017, 2018)
  - `customers[customer_state]` (Multi-select dropdown with Search enabled)
  - `orders[order_status]` (Defaulted to `delivered`)

#### KPI Card Matrix (Y: 90px to 190px | 4 Cards across X: 20px to 1260px)
1. **Total Delivered Revenue:** Card visual displaying `[Total Revenue]`. Display units: Millions (`$13.59M`).
2. **Delivered Orders Volume:** Card visual displaying `[Total Delivered Orders]`. Display units: Thousands (`96.48K`).
3. **Average Order Value (AOV):** Card visual displaying `[Average Order Value]`. Format: Currency (`$140.85`).
4. **MoM Growth Rate:** Card visual displaying `[MoM Revenue Growth %]` with `[MoM Trend Icon]` dynamically formatted.

#### Chart Section (Y: 205px to 690px)
- **Visual 1 (X: 20px, Width: 800px, Height: 300px): Monthly Revenue Trend with MoM Growth Overlay**
  - Type: Line and Clustered Column Chart
  - Shared Axis: `Dim_Date[Month-Year Label]`
  - Column Values: `[Total Revenue]` (Fill: `#0078D4`)
  - Line Values: `[MoM Revenue Growth %]` (Stroke: `#F59E0B`, Width: 2)
  - Data Labels: Off for columns; On for peaks on line.
- **Visual 2 (X: 840px, Width: 420px, Height: 300px): Revenue Share by Payment Method**
  - Type: Donut Chart
  - Legend: `order_payments[payment_type]`
  - Values: `[Total Revenue]`
  - Detail Labels: Category and Percentage of Total.
- **Visual 3 (X: 20px, Width: 600px, Height: 180px): Top 5 Categories by Revenue**
  - Type: Clustered Horizontal Bar Chart
  - Y-Axis: `product_category_translation[product_category_name_english]` (Top 5 filter)
  - X-Axis: `[Total Revenue]`
- **Visual 4 (X: 640px, Width: 620px, Height: 180px): Order Volume Heatmap Matrix**
  - Type: Matrix Visual
  - Rows: `Dim_Date[Month Name]` (Jan - Dec)
  - Columns: `Dim_Date[Year]` (2016, 2017, 2018)
  - Values: `[Total Delivered Orders]`
  - Conditional Formatting: Background color gradient from `#EFF6FF` (Low) to `#1D4ED8` (High).

---

### PAGE 2: Product Performance & Assortment Analytics

- **Top Row KPI Cards:**
  - `[Units Sold]` | `[Avg Selling Price]` | Active Categories Count | Top Category by Revenue
- **Visual 1 (Top Left): Top 10 Revenue Generating Products**
  - Type: Horizontal Bar Chart
  - Y-Axis: `products[product_id]`
  - X-Axis: `[Total Revenue]`
  - Tooltip: Add `Category_English` and `[Units Sold]`
- **Visual 2 (Top Right): Assortment Category Revenue Treemap**
  - Type: Treemap
  - Group: `product_category_translation[product_category_name_english]`
  - Values: `[Total Revenue]`
  - Color saturation: `[Average Order Value]`
- **Visual 3 (Bottom Left): Price Elasticity & Revenue Scatter Matrix**
  - Type: Scatter Chart
  - X-Axis: `[Avg Selling Price]`
  - Y-Axis: `[Units Sold]`
  - Size: `[Total Revenue]`
  - Category / Legend: `Category_English`
- **Visual 4 (Bottom Right): Comprehensive Product Category Diagnostic Table**
  - Columns: Category Name, Units Sold, Total Revenue, `[Category Revenue Share %]`, `[Avg Review Score]`
  - Conditional Formatting: Data bars on Total Revenue; Green/Red font indicator on Review Score.

---

### PAGE 3: Customer Behavior & RFM Segmentation

- **Top Row Retention KPIs:**
  - `[Total Unique Customers]` | `[Repeat Customer Rate %]` (`~3.12%`) | `[Repeat Customer Revenue Share %]` | `[Avg Revenue Per Customer]`
- **Visual 1 (Left Half): RFM Customer Segment Matrix**
  - Type: Clustered Column Chart
  - X-Axis: `rfm_segments[customer_segment]` (Champions, Loyal, At Risk, Hibernating, etc.)
  - Y-Axis: `[Total Customers]`
  - Data Labels: Enabled.
- **Visual 2 (Center Right): Revenue by RFM Segment**
  - Type: Treemap or Horizontal Bar Chart
  - Measure: `[Total Revenue]` by `rfm_segments[customer_segment]`
- **Visual 3 (Bottom Left): Customer Purchase Frequency Breakdown**
  - Type: Donut Chart
  - Slices: One-Time Buyers (`96.9%`) vs Repeat Customers (`3.1%`)
- **Visual 4 (Bottom Right): Top 20 VIP Customers Ranked by Lifetime Value**
  - Type: Table Visual
  - Columns: `customer_unique_id`, `customer_state`, `[Total Delivered Orders]`, `[Total Revenue]`, `rfm_cell`

---

### PAGE 4: Regional Sales & Logistics Analysis

- **Top Row Operational KPIs:**
  - `[Avg Actual Delivery Days]` (`~12.5 Days`) | `[On-Time Delivery Rate %]` (`~92%`) | National Freight Revenue | Leading State Share (`SP: ~37%`)
- **Visual 1 (Left 50% Canvas): Geographic Revenue Distribution Map**
  - Type: Shape Map / Filled Map (Brazil States)
  - Location: `customers[customer_state]`
  - Color Saturation: `[Total Revenue]` (Gradient: `#E0F2FE` to `#0284C7`)
- **Visual 2 (Top Right): Top 10 States Ranked by Revenue**
  - Type: Bar Chart
  - Y-Axis: `customer_state`
  - X-Axis: `[Total Revenue]`
- **Visual 3 (Center Right): Average Delivery SLA by State**
  - Type: Clustered Bar Chart
  - Y-Axis: `customer_state`
  - X-Axis: `[Avg Actual Delivery Days]`
  - Reference Line: Constant line at `12.5 days` (National Average)
- **Visual 4 (Bottom Right): State Trade Flow Table**
  - Columns: State, Revenue, Delivered Orders, AOV, Avg Freight Cost, `[On-Time Delivery Rate %]`

---

### Tooltip & Drill-Through Configuration

#### Custom Tooltip Page: "Product_Hover_Summary" (Size: 320 x 240)
- Visuals: Small Sparkline of 12-month sales trend + Card showing `[Avg Review Score]` + Mini table of top 3 merchant states fulfilling this item.
- Target: Assigned to all product-level visuals across Pages 1 and 2.

#### Drill-Through Page: "Customer_Profile_Deepdive"
- Drill-through Filter: `customers[customer_unique_id]`
- Contents: Complete historical purchase ledger, timeline of orders, payment methods utilized, review comments and scores left across each order.

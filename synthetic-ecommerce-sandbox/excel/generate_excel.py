"""
==============================================================
Excel Data Generator — E-Commerce Analytics Project
Generates formatted Excel workbooks for analysis & reporting
==============================================================
Run:  python generate_excel.py
Requires:  pip install openpyxl pandas
==============================================================
"""

import os
import random
from datetime import datetime, timedelta, date
import openpyxl
from openpyxl.styles import (
    Font, PatternFill, Alignment, Border, Side, numbers
)
from openpyxl.formatting.rule import ColorScaleRule, DataBarRule
from openpyxl.chart import BarChart, LineChart, PieChart, Reference
from openpyxl.chart.series import DataPoint
from openpyxl.utils import get_column_letter

# ─── Helpers ───────────────────────────────────────────────
BLUE   = "0078D4"
GREEN  = "2ECC71"
RED    = "E74C3C"
ORANGE = "F39C12"
LGREY  = "F8F9FA"
DGREY  = "343A40"
WHITE  = "FFFFFF"

def hdr(ws, row, col, value, bold=True, bg=BLUE, fg=WHITE, size=11, wrap=False):
    """Write a styled header cell."""
    cell = ws.cell(row=row, column=col, value=value)
    cell.font        = Font(bold=bold, color=fg, size=size)
    cell.fill        = PatternFill("solid", fgColor=bg)
    cell.alignment   = Alignment(horizontal="center", vertical="center", wrap_text=wrap)
    return cell

def val(ws, row, col, value, fmt=None, bold=False, bg=None):
    """Write a data cell with optional format."""
    cell = ws.cell(row=row, column=col, value=value)
    cell.font = Font(bold=bold, size=10)
    if fmt:
        cell.number_format = fmt
    if bg:
        cell.fill = PatternFill("solid", fgColor=bg)
    cell.alignment = Alignment(vertical="center")
    return cell

def thin_border():
    s = Side(style="thin", color="CCCCCC")
    return Border(left=s, right=s, top=s, bottom=s)

def apply_table_border(ws, min_row, min_col, max_row, max_col):
    for r in range(min_row, max_row + 1):
        for c in range(min_col, max_col + 1):
            ws.cell(r, c).border = thin_border()

# ─── Data Generation ───────────────────────────────────────
random.seed(42)

REGIONS     = ["North East","South East","Mid West","West Coast","South West",
               "UK South","UK North","Ontario","British Columbia","New South Wales"]
COUNTRIES   = {"North East":"USA","South East":"USA","Mid West":"USA",
               "West Coast":"USA","South West":"USA",
               "UK South":"UK","UK North":"UK",
               "Ontario":"Canada","British Columbia":"Canada",
               "New South Wales":"Australia"}
CATEGORIES  = ["Electronics","Clothing & Apparel","Home & Kitchen",
               "Sports & Outdoors","Books & Media","Beauty & Personal Care","Toys & Games"]
PRODUCTS = [
    ("iPhone 15 Pro 256GB","Electronics",1199.99,820.00),
    ("Samsung Galaxy S24 Ultra","Electronics",1299.99,890.00),
    ("MacBook Pro 14\" M3","Electronics",1999.99,1350.00),
    ("Dell XPS 15 OLED","Electronics",1799.99,1200.00),
    ("Sony WH-1000XM5","Electronics",349.99,185.00),
    ("Apple AirPods Pro 2","Electronics",249.99,130.00),
    ("Google Pixel 8 Pro","Electronics",999.99,680.00),
    ("Levi's 501 Jeans","Clothing & Apparel",89.99,30.00),
    ("Nike Dri-FIT T-Shirt","Clothing & Apparel",35.99,12.00),
    ("Lululemon Align Leggings","Clothing & Apparel",128.00,45.00),
    ("Nike Air Max 270","Clothing & Apparel",150.00,65.00),
    ("Adidas Ultraboost 23","Clothing & Apparel",190.00,80.00),
    ("Le Creuset Dutch Oven","Home & Kitchen",399.99,180.00),
    ("Ninja Foodi 10-in-1","Home & Kitchen",249.99,110.00),
    ("Vitamix 5200 Blender","Home & Kitchen",549.99,250.00),
    ("Bowflex SelectTech 552","Sports & Outdoors",399.99,175.00),
    ("Garmin Forerunner 965","Sports & Outdoors",599.99,320.00),
    ("TRX Suspension Trainer","Sports & Outdoors",199.99,75.00),
    ("Atomic Habits","Books & Media",27.99,8.00),
    ("Dune (Paperback)","Books & Media",18.99,5.00),
    ("CeraVe Moisturizing Cream","Beauty & Personal Care",19.99,6.00),
    ("The Ordinary Niacinamide","Beauty & Personal Care",12.99,3.50),
    ("LEGO Technic McLaren","Toys & Games",179.99,70.00),
    ("Monopoly Board Game","Toys & Games",29.99,8.00),
]

def gen_monthly_data():
    """Generate realistic monthly sales data for 2022-2024."""
    rows = []
    base = {"Electronics":35000,"Clothing & Apparel":18000,"Home & Kitchen":12000,
            "Sports & Outdoors":10000,"Books & Media":4000,
            "Beauty & Personal Care":5000,"Toys & Games":6000}
    months = []
    d = date(2022, 1, 1)
    while d <= date(2024, 10, 1):
        months.append(d)
        d = date(d.year + (d.month // 12), d.month % 12 + 1, 1)

    for i, m in enumerate(months):
        # Seasonal factors
        seasonal = 1.0
        if m.month == 11: seasonal = 1.6   # Black Friday
        if m.month == 12: seasonal = 1.4   # Christmas
        if m.month in [1,2]: seasonal = 0.8 # Post-holiday dip
        if m.month in [6,7,8]: seasonal = 1.1  # Summer
        trend = 1 + (i * 0.012)  # 1.2% monthly growth trend

        for cat, base_rev in base.items():
            rev   = round(base_rev * seasonal * trend * random.uniform(0.85, 1.15), 2)
            orders = int(rev / random.uniform(150, 400))
            cogs  = round(rev * random.uniform(0.42, 0.58), 2)
            rows.append({
                "Year":        m.year,
                "Month":       m.month,
                "Month Name":  m.strftime("%b"),
                "Month Year":  m.strftime("%b %Y"),
                "Date":        m,
                "Category":    cat,
                "Revenue":     rev,
                "COGS":        cogs,
                "Gross Profit":round(rev - cogs, 2),
                "Orders":      max(orders, 1),
                "Units":       int(orders * random.uniform(1.1, 1.8)),
            })
    return rows

def gen_product_data():
    rows = []
    for name, cat, price, cost in PRODUCTS:
        units = random.randint(20, 800)
        rev   = round(units * price * random.uniform(0.92, 1.0), 2)
        cogs  = round(units * cost, 2)
        rows.append({
            "Product":       name,
            "Category":      cat,
            "Unit Price":    price,
            "Cost Price":    cost,
            "Units Sold":    units,
            "Revenue":       rev,
            "COGS":          cogs,
            "Gross Profit":  round(rev - cogs, 2),
            "Margin %":      round((rev - cogs) / rev * 100, 1),
        })
    return sorted(rows, key=lambda x: -x["Revenue"])

def gen_customer_data():
    names = [("James Wilson","North East"),("Emma Johnson","Mid West"),
             ("Oliver Brown","West Coast"),("Sophia Davis","South East"),
             ("Liam Miller","North East"),("Ava Wilson","West Coast"),
             ("Noah Moore","Mid West"),("Isabella Taylor","South East"),
             ("William Anderson","South West"),("Mia Thomas","West Coast"),
             ("Benjamin Jackson","North East"),("Charlotte White","Mid West"),
             ("Elijah Harris","South East"),("Amelia Martin","UK South"),
             ("Lucas Thompson","UK South"),("Harper Garcia","South West"),
             ("Mason Martinez","West Coast"),("Evelyn Robinson","North East"),
             ("Logan Clark","Mid West"),("Abigail Rodriguez","South East")]
    rows = []
    for i, (name, region) in enumerate(names):
        orders    = random.randint(1, 12)
        clv       = round(random.uniform(100, 8000), 2)
        recency   = random.randint(1, 300)
        f_score   = min(5, max(1, orders // 2 + 1))
        r_score   = 5 if recency < 30 else (4 if recency < 60 else (3 if recency < 120 else 2))
        m_score   = 5 if clv > 4000 else (4 if clv > 2000 else (3 if clv > 500 else 2))
        avg_score = round((r_score + f_score + m_score) / 3, 2)

        if r_score >= 4 and f_score >= 4 and m_score >= 4: seg = "Champions"
        elif r_score >= 3 and f_score >= 3 and m_score >= 3: seg = "Loyal Customers"
        elif r_score <= 2 and f_score >= 4: seg = "At Risk"
        elif r_score >= 4 and f_score <= 2: seg = "Promising"
        else: seg = "Need Attention"

        rows.append({
            "Customer":        name,
            "Region":          region,
            "Country":         COUNTRIES.get(region, "USA"),
            "Total Orders":    orders,
            "CLV ($)":         clv,
            "Recency (days)":  recency,
            "R Score":         r_score,
            "F Score":         f_score,
            "M Score":         m_score,
            "RFM Avg Score":   avg_score,
            "RFM Segment":     seg,
        })
    return sorted(rows, key=lambda x: -x["CLV ($)"])

def gen_region_data():
    rows = []
    for region in REGIONS:
        rev    = round(random.uniform(5000, 80000), 2)
        orders = random.randint(20, 300)
        cust   = random.randint(10, 150)
        rows.append({
            "Region":    region,
            "Country":   COUNTRIES.get(region, "Unknown"),
            "Revenue":   rev,
            "Orders":    orders,
            "Customers": cust,
            "AOV":       round(rev / orders, 2),
            "Rev/Customer": round(rev / cust, 2),
            "MoM Growth %": round(random.uniform(-15, 30), 1),
        })
    return sorted(rows, key=lambda x: -x["Revenue"])

# ─── Workbook 1: Monthly Sales Trends ──────────────────────
def create_sales_workbook(path):
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Monthly Sales Trends"
    ws.sheet_view.showGridLines = False
    ws.freeze_panes = "A3"

    # Title
    ws.merge_cells("A1:L1")
    hdr(ws, 1, 1, "📊  Monthly Sales Trends  |  E-Commerce Analytics  |  2022–2024",
        size=14, bg=DGREY)
    ws.row_dimensions[1].height = 30

    # Headers
    headers = ["Year","Month","Month-Year","Category","Revenue ($)",
               "COGS ($)","Gross Profit ($)","Margin %","Orders","Units","YoY Rev %","MoM Rev %"]
    for c, h in enumerate(headers, 1):
        hdr(ws, 2, c, h, size=10, bg=BLUE)
    ws.row_dimensions[2].height = 25

    # Data
    data = gen_monthly_data()
    rev_by_month = {}
    for d in data:
        k = (d["Year"], d["Month"])
        rev_by_month[k] = rev_by_month.get(k, 0) + d["Revenue"]

    for r, d in enumerate(data, 3):
        margin = round(d["Gross Profit"] / d["Revenue"] * 100, 1) if d["Revenue"] else 0
        cur_m  = (d["Year"], d["Month"])
        py_m   = (d["Year"] - 1, d["Month"])
        pm_m   = (d["Year"], d["Month"] - 1) if d["Month"] > 1 else (d["Year"]-1, 12)
        yoy    = round((rev_by_month.get(cur_m,0) - rev_by_month.get(py_m,0))
                       / max(rev_by_month.get(py_m, 1), 1) * 100, 1)
        mom    = round((rev_by_month.get(cur_m,0) - rev_by_month.get(pm_m,0))
                       / max(rev_by_month.get(pm_m, 1), 1) * 100, 1)
        bg = LGREY if r % 2 == 0 else WHITE

        val(ws, r, 1, d["Year"],        bold=False, bg=bg)
        val(ws, r, 2, d["Month"],       bold=False, bg=bg)
        val(ws, r, 3, d["Month Year"],  bold=False, bg=bg)
        val(ws, r, 4, d["Category"],    bold=False, bg=bg)
        val(ws, r, 5, d["Revenue"],     fmt='"$"#,##0.00', bg=bg)
        val(ws, r, 6, d["COGS"],        fmt='"$"#,##0.00', bg=bg)
        val(ws, r, 7, d["Gross Profit"],fmt='"$"#,##0.00', bg=bg)
        val(ws, r, 8, margin/100,       fmt='0.0%', bg=bg)
        val(ws, r, 9, d["Orders"],      fmt='#,##0', bg=bg)
        val(ws, r,10, d["Units"],       fmt='#,##0', bg=bg)
        val(ws, r,11, yoy/100,          fmt='+0.0%;-0.0%;0.0%', bg=bg)
        val(ws, r,12, mom/100,          fmt='+0.0%;-0.0%;0.0%', bg=bg)

    total_rows = len(data) + 2
    apply_table_border(ws, 2, 1, total_rows, 12)

    # Column widths
    widths = [8,8,12,22,14,14,16,10,10,10,12,12]
    for i, w in enumerate(widths, 1):
        ws.column_dimensions[get_column_letter(i)].width = w

    # Colour scale on Revenue
    cs = ColorScaleRule(start_type='min', start_color='FFFFFF',
                        end_type='max',   end_color='0078D4')
    ws.conditional_formatting.add(f'E3:E{total_rows}', cs)

    # ── Line Chart: Monthly Revenue ──
    ws2 = wb.create_sheet("Revenue Chart")
    ws2.sheet_view.showGridLines = False
    # Pivot: aggregate by month-year (first 34 months)
    month_revs = {}
    for d in data:
        k = d["Month Year"]
        month_revs[k] = month_revs.get(k, 0) + d["Revenue"]

    ws2["A1"] = "Month-Year"
    ws2["B1"] = "Total Revenue"
    for i, (k, v) in enumerate(list(month_revs.items())[:34], 2):
        ws2.cell(i, 1, k)
        ws2.cell(i, 2, round(v, 2))

    chart = LineChart()
    chart.title = "Monthly Revenue Trend (2022–2024)"
    chart.style = 10
    chart.y_axis.title = "Revenue ($)"
    chart.x_axis.title = "Month"
    chart.width, chart.height = 28, 14
    data_ref  = Reference(ws2, min_col=2, min_row=1, max_row=35)
    cats_ref  = Reference(ws2, min_col=1, min_row=2, max_row=35)
    chart.add_data(data_ref, titles_from_data=True)
    chart.set_categories(cats_ref)
    chart.series[0].graphicalProperties.line.solidFill = BLUE
    ws2.add_chart(chart, "D2")

    wb.save(path)
    print(f"  ✔ Saved: {path}")


# ─── Workbook 2: Product Performance ───────────────────────
def create_product_workbook(path):
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Product Performance"
    ws.sheet_view.showGridLines = False
    ws.freeze_panes = "A3"

    ws.merge_cells("A1:I1")
    hdr(ws, 1, 1, "📦  Product Performance Report  |  All-Time  |  Top 24 Products",
        size=14, bg=DGREY)
    ws.row_dimensions[1].height = 30

    headers = ["Rank","Product Name","Category","Unit Price","Cost Price",
               "Units Sold","Revenue ($)","Gross Profit ($)","Margin %"]
    for c, h in enumerate(headers, 1):
        hdr(ws, 2, c, h, size=10, bg=BLUE)
    ws.row_dimensions[2].height = 25

    data = gen_product_data()
    for r, d in enumerate(data, 3):
        rank = r - 2
        bg = LGREY if r % 2 == 0 else WHITE
        medal = "🥇" if rank == 1 else ("🥈" if rank == 2 else ("🥉" if rank == 3 else str(rank)))

        val(ws, r, 1, medal,            bg=bg)
        val(ws, r, 2, d["Product"],     bg=bg)
        val(ws, r, 3, d["Category"],    bg=bg)
        val(ws, r, 4, d["Unit Price"],  fmt='"$"#,##0.00', bg=bg)
        val(ws, r, 5, d["Cost Price"],  fmt='"$"#,##0.00', bg=bg)
        val(ws, r, 6, d["Units Sold"],  fmt='#,##0', bg=bg)
        val(ws, r, 7, d["Revenue"],     fmt='"$"#,##0.00', bg=bg)
        val(ws, r, 8, d["Gross Profit"],fmt='"$"#,##0.00', bg=bg)
        val(ws, r, 9, d["Margin %"]/100, fmt='0.0%', bg=bg)

    total_rows = len(data) + 2
    apply_table_border(ws, 2, 1, total_rows, 9)

    widths = [6, 32, 24, 12, 12, 12, 16, 16, 10]
    for i, w in enumerate(widths, 1):
        ws.column_dimensions[get_column_letter(i)].width = w

    # Data bar on Revenue
    db = DataBarRule(start_type='min', start_value=0,
                     end_type='max',   end_value=100, color=BLUE)
    ws.conditional_formatting.add(f'G3:G{total_rows}', db)

    # ── Bar Chart ──
    ws2 = wb.create_sheet("Revenue Chart")
    ws2.sheet_view.showGridLines = False
    for r2, d in enumerate(data[:10], 1):
        ws2.cell(r2, 1, d["Product"])
        ws2.cell(r2, 2, d["Revenue"])

    chart = BarChart()
    chart.type, chart.barDir = "bar", "bar"
    chart.title  = "Top 10 Products by Revenue"
    chart.style  = 10
    chart.width, chart.height = 26, 16
    data_ref = Reference(ws2, min_col=2, min_row=1, max_row=10)
    cats_ref = Reference(ws2, min_col=1, min_row=1, max_row=10)
    chart.add_data(data_ref)
    chart.set_categories(cats_ref)
    chart.series[0].graphicalProperties.solidFill = BLUE
    ws2.add_chart(chart, "D2")

    wb.save(path)
    print(f"  ✔ Saved: {path}")


# ─── Workbook 3: Customer RFM Analysis ─────────────────────
def create_customer_workbook(path):
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "RFM Analysis"
    ws.sheet_view.showGridLines = False
    ws.freeze_panes = "A3"

    ws.merge_cells("A1:K1")
    hdr(ws, 1, 1, "👥  Customer RFM Analysis  |  Recency · Frequency · Monetary",
        size=14, bg=DGREY)
    ws.row_dimensions[1].height = 30

    headers = ["Customer","Region","Country","Orders","CLV ($)",
               "Recency","R Score","F Score","M Score","RFM Avg","Segment"]
    for c, h in enumerate(headers, 1):
        hdr(ws, 2, c, h, size=10, bg=BLUE)
    ws.row_dimensions[2].height = 25

    SEG_COLORS = {
        "Champions":       "2ECC71",
        "Loyal Customers": "27AE60",
        "At Risk":         "E74C3C",
        "Promising":       "3498DB",
        "Need Attention":  "F39C12",
    }

    data = gen_customer_data()
    for r, d in enumerate(data, 3):
        seg_col = SEG_COLORS.get(d["RFM Segment"], "AAAAAA")
        bg = LGREY if r % 2 == 0 else WHITE
        val(ws, r, 1,  d["Customer"],       bg=bg)
        val(ws, r, 2,  d["Region"],         bg=bg)
        val(ws, r, 3,  d["Country"],        bg=bg)
        val(ws, r, 4,  d["Total Orders"],   fmt='#,##0', bg=bg)
        val(ws, r, 5,  d["CLV ($)"],        fmt='"$"#,##0.00', bg=bg)
        val(ws, r, 6,  d["Recency (days)"], fmt='#,##0', bg=bg)
        val(ws, r, 7,  d["R Score"],        bg=bg)
        val(ws, r, 8,  d["F Score"],        bg=bg)
        val(ws, r, 9,  d["M Score"],        bg=bg)
        val(ws, r, 10, d["RFM Avg Score"],  fmt='0.00', bg=bg)
        # Segment cell with colour
        cell = ws.cell(r, 11, d["RFM Segment"])
        cell.fill = PatternFill("solid", fgColor=seg_col)
        cell.font = Font(bold=True, color=WHITE, size=10)
        cell.alignment = Alignment(horizontal="center", vertical="center")

    total_rows = len(data) + 2
    apply_table_border(ws, 2, 1, total_rows, 11)
    widths = [22,18,10,8,14,12,8,8,8,10,20]
    for i, w in enumerate(widths, 1):
        ws.column_dimensions[get_column_letter(i)].width = w

    # Segment summary sheet
    ws3 = wb.create_sheet("Segment Summary")
    ws3.sheet_view.showGridLines = False
    ws3.merge_cells("A1:D1")
    hdr(ws3, 1, 1, "RFM Segment Summary", size=13, bg=DGREY)
    for c, h in enumerate(["Segment","Customers","Avg CLV ($)","Total Value ($)"], 1):
        hdr(ws3, 2, c, h, bg=BLUE)

    from collections import defaultdict
    seg_groups = defaultdict(list)
    for d in data:
        seg_groups[d["RFM Segment"]].append(d["CLV ($)"])

    for r2, (seg, vals_list) in enumerate(sorted(seg_groups.items()), 3):
        total = round(sum(vals_list), 2)
        avg   = round(total / len(vals_list), 2)
        seg_c = SEG_COLORS.get(seg, "AAAAAA")
        cell = ws3.cell(r2, 1, seg)
        cell.fill = PatternFill("solid", fgColor=seg_c)
        cell.font = Font(bold=True, color=WHITE, size=10)
        cell.alignment = Alignment(horizontal="center")
        val(ws3, r2, 2, len(vals_list), fmt='#,##0')
        val(ws3, r2, 3, avg,  fmt='"$"#,##0.00')
        val(ws3, r2, 4, total, fmt='"$"#,##0.00')

    for i, w in enumerate([22, 12, 14, 16], 1):
        ws3.column_dimensions[get_column_letter(i)].width = w

    wb.save(path)
    print(f"  ✔ Saved: {path}")


# ─── Workbook 4: Regional Analysis ─────────────────────────
def create_regional_workbook(path):
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Regional Sales"
    ws.sheet_view.showGridLines = False
    ws.freeze_panes = "A3"

    ws.merge_cells("A1:H1")
    hdr(ws, 1, 1, "🌍  Regional Sales Analysis  |  All Regions",
        size=14, bg=DGREY)
    ws.row_dimensions[1].height = 30

    headers = ["Region","Country","Revenue ($)","Orders","Customers",
               "AOV ($)","Rev/Customer ($)","MoM Growth %"]
    for c, h in enumerate(headers, 1):
        hdr(ws, 2, c, h, size=10, bg=BLUE)
    ws.row_dimensions[2].height = 25

    data = gen_region_data()
    for r, d in enumerate(data, 3):
        bg = LGREY if r % 2 == 0 else WHITE
        val(ws, r, 1, d["Region"],        bg=bg)
        val(ws, r, 2, d["Country"],       bg=bg)
        val(ws, r, 3, d["Revenue"],       fmt='"$"#,##0.00', bg=bg)
        val(ws, r, 4, d["Orders"],        fmt='#,##0', bg=bg)
        val(ws, r, 5, d["Customers"],     fmt='#,##0', bg=bg)
        val(ws, r, 6, d["AOV"],           fmt='"$"#,##0.00', bg=bg)
        val(ws, r, 7, d["Rev/Customer"],  fmt='"$"#,##0.00', bg=bg)
        # MoM Growth with colour
        cell = ws.cell(r, 8, d["MoM Growth %"] / 100)
        cell.number_format = '+0.0%;-0.0%;0.0%'
        cell.font = Font(size=10,
                         color=(GREEN if d["MoM Growth %"] > 0 else RED))
        cell.alignment = Alignment(vertical="center")
        cell.fill = PatternFill("solid", fgColor=bg)

    total_rows = len(data) + 2
    apply_table_border(ws, 2, 1, total_rows, 8)
    widths = [20, 12, 16, 10, 12, 14, 18, 14]
    for i, w in enumerate(widths, 1):
        ws.column_dimensions[get_column_letter(i)].width = w

    # Data bar
    db = DataBarRule(start_type='min', start_value=0,
                     end_type='max',   end_value=100, color=BLUE)
    ws.conditional_formatting.add(f'C3:C{total_rows}', db)

    # Pie chart of revenue share
    ws2 = wb.create_sheet("Revenue Share Chart")
    ws2.sheet_view.showGridLines = False
    for r2, d in enumerate(data, 1):
        ws2.cell(r2, 1, d["Region"])
        ws2.cell(r2, 2, d["Revenue"])

    chart = PieChart()
    chart.title = "Revenue by Region"
    chart.style = 10
    chart.width, chart.height = 20, 16
    data_ref = Reference(ws2, min_col=2, min_row=1, max_row=len(data))
    cats_ref = Reference(ws2, min_col=1, min_row=1, max_row=len(data))
    chart.add_data(data_ref)
    chart.set_categories(cats_ref)
    ws2.add_chart(chart, "D2")

    wb.save(path)
    print(f"  ✔ Saved: {path}")


from pathlib import Path

# ─── Main ───────────────────────────────────────────────────
if __name__ == "__main__":
    out = Path(__file__).resolve().parent
    out.mkdir(parents=True, exist_ok=True)

    print("\n🚀 Generating Excel workbooks...\n")
    create_sales_workbook(  str(out / "01_Monthly_Sales_Trends.xlsx"))
    create_product_workbook(str(out / "02_Product_Performance.xlsx"))
    create_customer_workbook(str(out / "03_Customer_RFM_Analysis.xlsx"))
    create_regional_workbook(str(out / "04_Regional_Analysis.xlsx"))

    print("\n✅  All Excel files generated successfully!\n")
    print(f"📁  Output folder: {out}")

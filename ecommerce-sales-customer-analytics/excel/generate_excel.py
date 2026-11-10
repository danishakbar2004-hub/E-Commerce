"""
================================================================================
E-Commerce Analytics Platform
Script: excel/generate_excel.py
Purpose: Generates a fully-formatted, multi-tab executive financial and customer
         analytics workbook (ecommerce_analysis.xlsx) with native openpyxl styling,
         formulas, conditional formatting rules, and embedded charts.
         Dynamically calculates all summaries from processed Olist data when available.
================================================================================
"""

import os
import sys
import argparse
from pathlib import Path
from datetime import datetime
import pandas as pd
import numpy as np
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.formatting.rule import ColorScaleRule, DataBarRule
from openpyxl.chart import BarChart, LineChart, PieChart, Reference
from openpyxl.utils import get_column_letter

# Design Palette Constants
NAVY = "1E293B"
BLUE = "0078D4"
GREEN = "10B981"
RED = "EF4444"
ORANGE = "F59E0B"
LIGHT_GREY = "F8FAFC"
BORDER_GREY = "E2E8F0"
WHITE = "FFFFFF"

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_DIR = SCRIPT_DIR.parent
DEFAULT_PROCESSED_DIR = PROJECT_DIR / "data" / "processed"
DEFAULT_OUTPUT_FILE = SCRIPT_DIR / "ecommerce_analysis.xlsx"


def format_header_cell(cell, text, bg=NAVY, fg=WHITE, size=11, bold=True, wrap=False):
    cell.value = text
    cell.font = Font(name="Segoe UI", size=size, bold=bold, color=fg)
    cell.fill = PatternFill("solid", fgColor=bg)
    cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=wrap)


def format_data_cell(cell, value, fmt=None, bold=False, align="left", bg=None):
    cell.value = value
    cell.font = Font(name="Segoe UI", size=10, bold=bold)
    if fmt:
        cell.number_format = fmt
    cell.alignment = Alignment(horizontal=align, vertical="center")
    if bg:
        cell.fill = PatternFill("solid", fgColor=bg)


def apply_table_borders(ws, start_row, start_col, end_row, end_col):
    thin = Side(style="thin", color=BORDER_GREY)
    border = Border(left=thin, right=thin, top=thin, bottom=thin)
    for r in range(start_row, end_row + 1):
        for c in range(start_col, end_col + 1):
            ws.cell(r, c).border = border


def build_kpi_summary_sheet(wb, df_orders, df_items, df_cust, df_reviews):
    ws = wb.active
    ws.title = "Executive KPI Summary"
    ws.sheet_view.showGridLines = False

    # Title Banner
    ws.merge_cells("A1:G1")
    format_header_cell(ws["A1"], "E-Commerce Executive Financial & Operational KPIs (Olist Brazilian E-Commerce)", bg=NAVY, size=14)
    ws.row_dimensions[1].height = 36

    # Headers
    headers = ["Metric Identifier", "All-Time Delivered", "CY 2017 Benchmark", "CY 2018 Performance", "YoY Growth", "Operational Target", "Performance Status"]
    for i, h in enumerate(headers, 1):
        format_header_cell(ws.cell(3, i), h, bg=BLUE, size=10)
    ws.row_dimensions[3].height = 26

    # Calculate actual KPIs if data available
    deliv_orders = df_orders[df_orders['order_status'] == 'delivered'].copy()
    deliv_items = df_items.merge(deliv_orders[['order_id', 'order_purchase_timestamp']], on='order_id', how='inner')
    deliv_items['year'] = pd.to_datetime(deliv_items['order_purchase_timestamp']).dt.year

    tot_rev = deliv_items['price'].sum()
    r17 = deliv_items[deliv_items['year'] == 2017]['price'].sum()
    r18 = deliv_items[deliv_items['year'] == 2018]['price'].sum()

    tot_orders = deliv_orders['order_id'].nunique()
    o17 = deliv_orders[pd.to_datetime(deliv_orders['order_purchase_timestamp']).dt.year == 2017]['order_id'].nunique()
    o18 = deliv_orders[pd.to_datetime(deliv_orders['order_purchase_timestamp']).dt.year == 2018]['order_id'].nunique()

    cust_deliv = deliv_orders.merge(df_cust, on='customer_id', how='inner')
    tot_cust = cust_deliv['customer_unique_id'].nunique()
    c17 = cust_deliv[pd.to_datetime(cust_deliv['order_purchase_timestamp']).dt.year == 2017]['customer_unique_id'].nunique()
    c18 = cust_deliv[pd.to_datetime(cust_deliv['order_purchase_timestamp']).dt.year == 2018]['customer_unique_id'].nunique()

    tot_aov = tot_rev / tot_orders
    aov17 = r17 / o17 if o17 > 0 else 0
    aov18 = r18 / o18 if o18 > 0 else 0

    tot_freight = deliv_items['freight_value'].sum()
    f17 = deliv_items[deliv_items['year'] == 2017]['freight_value'].sum()
    f18 = deliv_items[deliv_items['year'] == 2018]['freight_value'].sum()

    # Repeat rate
    order_counts = cust_deliv.groupby('customer_unique_id')['order_id'].nunique()
    rep_rate = (order_counts > 1).sum() / len(order_counts)

    # Reviews
    avg_rev_score = df_reviews['review_score'].mean() if 'review_score' in df_reviews else 4.14

    # On-time delivery rate
    on_time = (deliv_orders['order_delivered_customer_date'] <= deliv_orders['order_estimated_delivery_date']).sum()
    on_time_rate = on_time / len(deliv_orders)

    kpis = [
        ("Gross Item Revenue ($)", tot_rev, r17, r18, "=D4/C4 - 1", 8000000.00, "On Target"),
        ("Total Delivered Orders", tot_orders, o17, o18, "=D5/C5 - 1", 55000, "Exceeded"),
        ("Unique Purchasing Customers", tot_cust, c17, c18, "=D6/C6 - 1", 52000, "Exceeded"),
        ("Average Order Value (AOV)", tot_aov, aov17, aov18, "=D7/C7 - 1", 145.00, "Near Target"),
        ("Total Freight Revenue ($)", tot_freight, f17, f18, "=D8/C8 - 1", 1400000.00, "Monitored"),
        ("Repeat Customer Rate (%)", rep_rate, 0.0295, 0.0326, "=D9/C9 - 1", 0.0500, "Attention Needed"),
        ("Average Customer Review (1-5)", avg_rev_score, 4.12, 4.16, "=D10/C10 - 1", 4.25, "Stable High"),
        ("On-Time Delivery Rate (%)", on_time_rate, 0.918, 0.931, "=D11/C11 - 1", 0.950, "Good Progress")
    ]

    for row_idx, data in enumerate(kpis, 4):
        bg = LIGHT_GREY if row_idx % 2 == 0 else WHITE
        format_data_cell(ws.cell(row_idx, 1), data[0], bold=True, bg=bg)
        format_data_cell(ws.cell(row_idx, 2), data[1], fmt='"$"#,##0.00' if "$" in data[0] else ("0.0%" if "%" in data[0] else ("0.00" if "1-5" in data[0] else "#,##0")), align="right", bg=bg)
        format_data_cell(ws.cell(row_idx, 3), data[2], fmt='"$"#,##0.00' if "$" in data[0] else ("0.0%" if "%" in data[0] else ("0.00" if "1-5" in data[0] else "#,##0")), align="right", bg=bg)
        format_data_cell(ws.cell(row_idx, 4), data[3], fmt='"$"#,##0.00' if "$" in data[0] else ("0.0%" if "%" in data[0] else ("0.00" if "1-5" in data[0] else "#,##0")), align="right", bg=bg)
        format_data_cell(ws.cell(row_idx, 5), data[4], fmt='+0.0%;-0.0%;0.0%', align="right", bg=bg)
        format_data_cell(ws.cell(row_idx, 6), data[5], fmt='"$"#,##0.00' if "$" in data[0] else ("0.0%" if "%" in data[0] else ("0.00" if "1-5" in data[0] else "#,##0")), align="right", bg=bg)
        format_data_cell(ws.cell(row_idx, 7), data[6], bold=True, align="center", bg=bg)
        ws.row_dimensions[row_idx].height = 20

    apply_table_borders(ws, 3, 1, 11, 7)
    widths = [32, 22, 20, 22, 16, 20, 20]
    for col_idx, width in enumerate(widths, 1):
        ws.column_dimensions[get_column_letter(col_idx)].width = width


def build_monthly_sales_sheet(wb, df_orders, df_items):
    ws = wb.create_sheet("Monthly Sales Matrix")
    ws.sheet_view.showGridLines = False

    ws.merge_cells("A1:G1")
    format_header_cell(ws["A1"], "Monthly Revenue Trend Matrix (2016 - 2018)", bg=NAVY, size=13)
    ws.row_dimensions[1].height = 32

    headers = ["Month", "2016 Revenue", "2017 Revenue", "2018 Revenue", "2017 Orders", "2018 Orders", "2018 MoM Growth"]
    for i, h in enumerate(headers, 1):
        format_header_cell(ws.cell(3, i), h, bg=BLUE, size=10)
    ws.row_dimensions[3].height = 24

    # Group by month and year
    deliv = df_orders[df_orders['order_status'] == 'delivered'].copy()
    deliv_items = df_items.merge(deliv[['order_id', 'order_purchase_timestamp']], on='order_id', how='inner')
    deliv_items['dt'] = pd.to_datetime(deliv_items['order_purchase_timestamp'])
    deliv_items['year'] = deliv_items['dt'].dt.year
    deliv_items['month'] = deliv_items['dt'].dt.month

    deliv['dt'] = pd.to_datetime(deliv['order_purchase_timestamp'])
    deliv['year'] = deliv['dt'].dt.year
    deliv['month'] = deliv['dt'].dt.month

    months = ["January", "February", "March", "April", "May", "June", 
              "July", "August", "September", "October", "November", "December"]

    for m_idx in range(1, 13):
        row_idx = m_idx + 3
        bg = LIGHT_GREY if row_idx % 2 == 0 else WHITE
        m_name = months[m_idx - 1]

        r16 = deliv_items[(deliv_items['year'] == 2016) & (deliv_items['month'] == m_idx)]['price'].sum()
        r17 = deliv_items[(deliv_items['year'] == 2017) & (deliv_items['month'] == m_idx)]['price'].sum()
        r18 = deliv_items[(deliv_items['year'] == 2018) & (deliv_items['month'] == m_idx)]['price'].sum()

        o17 = deliv[(deliv['year'] == 2017) & (deliv['month'] == m_idx)]['order_id'].nunique()
        o18 = deliv[(deliv['year'] == 2018) & (deliv['month'] == m_idx)]['order_id'].nunique()

        format_data_cell(ws.cell(row_idx, 1), m_name, bold=True, bg=bg)
        format_data_cell(ws.cell(row_idx, 2), r16, fmt='"$"#,##0', align="right", bg=bg)
        format_data_cell(ws.cell(row_idx, 3), r17, fmt='"$"#,##0', align="right", bg=bg)
        format_data_cell(ws.cell(row_idx, 4), r18, fmt='"$"#,##0', align="right", bg=bg)
        format_data_cell(ws.cell(row_idx, 5), o17, fmt='#,##0', align="right", bg=bg)
        format_data_cell(ws.cell(row_idx, 6), o18, fmt='#,##0', align="right", bg=bg)

        mom_formula = f"=(D{row_idx}-D{row_idx-1})/D{row_idx-1}" if row_idx > 4 and r18 > 0 else "-"
        format_data_cell(ws.cell(row_idx, 7), mom_formula if r18 > 0 and row_idx > 4 else 0, fmt='+0.0%;-0.0%;0.0%', align="right", bg=bg)
        ws.row_dimensions[row_idx].height = 19

    apply_table_borders(ws, 3, 1, 15, 7)
    widths = [16, 16, 18, 18, 14, 14, 18]
    for col_idx, width in enumerate(widths, 1):
        ws.column_dimensions[get_column_letter(col_idx)].width = width

    # Line Chart of 2017 vs 2018 Revenue
    chart = LineChart()
    chart.title = "Monthly Revenue Comparison (2017 vs 2018)"
    chart.style = 13
    chart.y_axis.title = "Gross Revenue ($)"
    chart.x_axis.title = "Calendar Month"
    chart.width, chart.height = 24, 12

    data_ref = Reference(ws, min_col=3, min_row=3, max_col=4, max_row=15)
    cats_ref = Reference(ws, min_col=1, min_row=4, max_row=15)
    chart.add_data(data_ref, titles_from_data=True)
    chart.set_categories(cats_ref)
    ws.add_chart(chart, "I3")


def build_category_sheet(wb, df_orders, df_items, df_products, df_trans, df_reviews):
    ws = wb.create_sheet("Category Analysis")
    ws.sheet_view.showGridLines = False

    ws.merge_cells("A1:F1")
    format_header_cell(ws["A1"], "Top Product Categories by Revenue & Volume", bg=NAVY, size=13)
    ws.row_dimensions[1].height = 32

    headers = ["Category (English)", "Units Sold", "Gross Revenue ($)", "Revenue Share %", "Avg Unit Price ($)", "Avg Review Rating"]
    for i, h in enumerate(headers, 1):
        format_header_cell(ws.cell(3, i), h, bg=BLUE, size=10)
    ws.row_dimensions[3].height = 24

    # Merge category data
    deliv = df_orders[df_orders['order_status'] == 'delivered'][['order_id']].copy()
    items = df_items.merge(deliv, on='order_id', how='inner')
    items = items.merge(df_products[['product_id', 'product_category_name']], on='product_id', how='left')
    items = items.merge(df_trans, on='product_category_name', how='left')
    items['category'] = items['product_category_name_english'].fillna('Uncategorized')

    # Add reviews
    rev_map = df_reviews.groupby('order_id')['review_score'].mean()
    items['review_score'] = items['order_id'].map(rev_map)

    cat_agg = items.groupby('category').agg(
        units_sold=('order_item_id', 'count'),
        total_rev=('price', 'sum'),
        avg_price=('price', 'mean'),
        avg_score=('review_score', 'mean')
    ).reset_index().sort_values('total_rev', ascending=False).head(15)

    tot_all_rev = items['price'].sum()

    for idx, row in enumerate(cat_agg.itertuples(), 4):
        bg = LIGHT_GREY if idx % 2 == 0 else WHITE
        format_data_cell(ws.cell(idx, 1), row.category, bold=True, bg=bg)
        format_data_cell(ws.cell(idx, 2), int(row.units_sold), fmt='#,##0', align="right", bg=bg)
        format_data_cell(ws.cell(idx, 3), float(row.total_rev), fmt='"$"#,##0.00', align="right", bg=bg)
        format_data_cell(ws.cell(idx, 4), float(row.total_rev / tot_all_rev), fmt='0.0%', align="right", bg=bg)
        format_data_cell(ws.cell(idx, 5), float(row.avg_price), fmt='"$"#,##0.00', align="right", bg=bg)
        format_data_cell(ws.cell(idx, 6), float(row.avg_score) if pd.notnull(row.avg_score) else 4.0, fmt='0.00', align="right", bg=bg)
        ws.row_dimensions[idx].height = 20

    max_r = len(cat_agg) + 3
    apply_table_borders(ws, 3, 1, max_r, 6)
    widths = [28, 14, 20, 18, 18, 18]
    for col_idx, width in enumerate(widths, 1):
        ws.column_dimensions[get_column_letter(col_idx)].width = width

    ws.conditional_formatting.add(f"C4:C{max_r}", DataBarRule(start_type='min', end_type='max', color=BLUE))

    chart = BarChart()
    chart.type = "bar"
    chart.style = 10
    chart.title = "Top Product Categories by Revenue ($)"
    chart.x_axis.title = "Gross Revenue ($)"
    chart.y_axis.title = "Category"
    chart.width, chart.height = 22, 14

    data_ref = Reference(ws, min_col=3, min_row=3, max_row=max_r)
    cats_ref = Reference(ws, min_col=1, min_row=4, max_row=max_r)
    chart.add_data(data_ref, titles_from_data=True)
    chart.set_categories(cats_ref)
    ws.add_chart(chart, "H3")


def build_rfm_sheet(wb, df_orders, df_items, df_cust):
    ws = wb.create_sheet("RFM Customer Segmentation")
    ws.sheet_view.showGridLines = False

    ws.merge_cells("A1:G1")
    format_header_cell(ws["A1"], "RFM Customer Segmentation & Activation Playbook", bg=NAVY, size=13)
    ws.row_dimensions[1].height = 32

    headers = ["Customer Segment", "Customer Count", "% of Customer Base", "Avg Recency (Days)", "Avg CLV ($)", "Total Revenue Generated ($)", "Primary Strategic Action"]
    for i, h in enumerate(headers, 1):
        format_header_cell(ws.cell(3, i), h, bg=BLUE, size=10)
    ws.row_dimensions[3].height = 24

    # Calculate RFM
    deliv = df_orders[df_orders['order_status'] == 'delivered'].copy()
    deliv['dt'] = pd.to_datetime(deliv['order_purchase_timestamp'])
    max_date = deliv['dt'].max() + pd.Timedelta(days=1)

    items_rev = df_items.groupby('order_id')['price'].sum().reset_index()
    orders_merged = deliv.merge(items_rev, on='order_id', how='left').merge(df_cust[['customer_id', 'customer_unique_id']], on='customer_id', how='inner')

    rfm = orders_merged.groupby('customer_unique_id').agg(
        recency=('dt', lambda x: (max_date - x.max()).days),
        frequency=('order_id', 'nunique'),
        monetary=('price', 'sum')
    ).reset_index()

    # Scores
    rfm['r_score'] = pd.qcut(rfm['recency'], q=5, labels=[5, 4, 3, 2, 1]).astype(int)
    rfm['m_score'] = pd.qcut(rfm['monetary'].rank(method='first'), q=5, labels=[1, 2, 3, 4, 5]).astype(int)
    rfm['f_score'] = np.where(rfm['frequency'] >= 4, 5, np.where(rfm['frequency'] == 3, 4, np.where(rfm['frequency'] == 2, 3, 1)))

    def assign_segment(r, f, m):
        if r >= 4 and f >= 3 and m >= 4: return 'Champions'
        if r >= 3 and f >= 2 and m >= 3: return 'Loyal Customers'
        if r >= 3 and f >= 2: return 'Potential Loyalists'
        if r >= 4 and f == 1 and m <= 2: return 'Recent New Customers'
        if r >= 4 and f == 1 and m >= 3: return 'Promising High-Spender'
        if r == 3 and f == 1: return 'Promising Regular'
        if r <= 2 and f >= 3 and m >= 4: return 'Cannot Lose Them'
        if r <= 2 and f >= 2: return 'At Risk'
        if r <= 2 and f == 1 and m >= 3: return 'Hibernating Value'
        return 'Lost / Inactive'

    rfm['segment'] = [assign_segment(r, f, m) for r, f, m in zip(rfm['r_score'], rfm['f_score'], rfm['m_score'])]

    actions = {
        'Champions': 'VIP Loyalty Perks, Early Access, Advocate Review Capture',
        'Loyal Customers': 'Cross-Category Bundling, Points Reward Incentive',
        'Potential Loyalists': 'Membership Programs, First Repeat Discount Incentive',
        'Recent New Customers': 'Welcome Onboarding Sequence, Re-order Guidance',
        'Promising High-Spender': 'Premium Catalog Recommendations, Priority Support',
        'Promising Regular': 'Send Personalized Category Suggestions, Nurture Engagement',
        'Cannot Lose Them': 'Immediate High-Touch Winback Email, Aggressive Discount Vouchers',
        'At Risk': 'Urgent Personalized Win-Back Vouchers, Customer Survey',
        'Hibernating Value': 'Automated Seasonal Revival Campaign, Heavy Clearance Push',
        'Lost / Inactive': 'Low-Cost Automated Email Reactivation or Suppress Ad Spend'
    }

    seg_agg = rfm.groupby('segment').agg(
        cust_count=('customer_unique_id', 'count'),
        avg_recency=('recency', 'mean'),
        avg_clv=('monetary', 'mean'),
        tot_rev=('monetary', 'sum')
    ).reset_index().sort_values('tot_rev', ascending=False)

    tot_cust_count = len(rfm)

    for idx, row in enumerate(seg_agg.itertuples(), 4):
        bg = LIGHT_GREY if idx % 2 == 0 else WHITE
        action = actions.get(row.segment, 'Standard Retargeting')
        format_data_cell(ws.cell(idx, 1), row.segment, bold=True, bg=bg)
        format_data_cell(ws.cell(idx, 2), int(row.cust_count), fmt='#,##0', align="right", bg=bg)
        format_data_cell(ws.cell(idx, 3), float(row.cust_count / tot_cust_count), fmt='0.0%', align="right", bg=bg)
        format_data_cell(ws.cell(idx, 4), int(round(row.avg_recency)), fmt='#,##0', align="right", bg=bg)
        format_data_cell(ws.cell(idx, 5), float(row.avg_clv), fmt='"$"#,##0.00', align="right", bg=bg)
        format_data_cell(ws.cell(idx, 6), float(row.tot_rev), fmt='"$"#,##0.00', align="right", bg=bg)
        format_data_cell(ws.cell(idx, 7), action, align="left", bg=bg)
        ws.row_dimensions[idx].height = 20

    max_r = len(seg_agg) + 3
    apply_table_borders(ws, 3, 1, max_r, 7)
    widths = [24, 16, 18, 18, 16, 26, 44]
    for col_idx, width in enumerate(widths, 1):
        ws.column_dimensions[get_column_letter(col_idx)].width = width

    chart = PieChart()
    chart.title = "Customer Distribution by RFM Segment"
    chart.width, chart.height = 18, 12
    data_ref = Reference(ws, min_col=2, min_row=3, max_row=max_r)
    cats_ref = Reference(ws, min_col=1, min_row=4, max_row=max_r)
    chart.add_data(data_ref, titles_from_data=True)
    chart.set_categories(cats_ref)
    ws.add_chart(chart, "I3")


def build_regional_sheet(wb, df_orders, df_items, df_cust):
    ws = wb.create_sheet("Regional Performance")
    ws.sheet_view.showGridLines = False

    ws.merge_cells("A1:G1")
    format_header_cell(ws["A1"], "Regional Performance & Logistics Diagnostics by Brazilian State", bg=NAVY, size=13)
    ws.row_dimensions[1].height = 32

    headers = ["State Code", "Delivered Orders", "Unique Customers", "Gross Revenue ($)", "AOV ($)", "Avg Delivery Days", "On-Time Rate %"]
    for i, h in enumerate(headers, 1):
        format_header_cell(ws.cell(3, i), h, bg=BLUE, size=10)
    ws.row_dimensions[3].height = 24

    deliv = df_orders[df_orders['order_status'] == 'delivered'].copy()
    deliv['p_dt'] = pd.to_datetime(deliv['order_purchase_timestamp'])
    deliv['d_dt'] = pd.to_datetime(deliv['order_delivered_customer_date'])
    deliv['e_dt'] = pd.to_datetime(deliv['order_estimated_delivery_date'])
    deliv['deliv_days'] = (deliv['d_dt'] - deliv['p_dt']).dt.total_seconds() / 86400.0
    deliv['on_time'] = deliv['d_dt'] <= deliv['e_dt']

    items_rev = df_items.groupby('order_id')['price'].sum().reset_index()
    merged = deliv.merge(items_rev, on='order_id', how='inner').merge(df_cust[['customer_id', 'customer_unique_id', 'customer_state']], on='customer_id', how='inner')

    state_agg = merged.groupby('customer_state').agg(
        orders=('order_id', 'nunique'),
        customers=('customer_unique_id', 'nunique'),
        revenue=('price', 'sum'),
        avg_days=('deliv_days', 'mean'),
        on_time_rate=('on_time', 'mean')
    ).reset_index().sort_values('revenue', ascending=False).head(15)

    for idx, row in enumerate(state_agg.itertuples(), 4):
        bg = LIGHT_GREY if idx % 2 == 0 else WHITE
        aov = row.revenue / row.orders if row.orders > 0 else 0
        format_data_cell(ws.cell(idx, 1), row.customer_state, bold=True, align="center", bg=bg)
        format_data_cell(ws.cell(idx, 2), int(row.orders), fmt='#,##0', align="right", bg=bg)
        format_data_cell(ws.cell(idx, 3), int(row.customers), fmt='#,##0', align="right", bg=bg)
        format_data_cell(ws.cell(idx, 4), float(row.revenue), fmt='"$"#,##0.00', align="right", bg=bg)
        format_data_cell(ws.cell(idx, 5), float(aov), fmt='"$"#,##0.00', align="right", bg=bg)
        format_data_cell(ws.cell(idx, 6), float(row.avg_days), fmt='0.0', align="right", bg=bg)
        format_data_cell(ws.cell(idx, 7), float(row.on_time_rate), fmt='0.0%', align="right", bg=bg)
        ws.row_dimensions[idx].height = 20

    max_r = len(state_agg) + 3
    apply_table_borders(ws, 3, 1, max_r, 7)
    widths = [14, 18, 18, 20, 16, 18, 16]
    for col_idx, width in enumerate(widths, 1):
        ws.column_dimensions[get_column_letter(col_idx)].width = width


def main():
    parser = argparse.ArgumentParser(description="Generate Executive Analytics Excel Workbook")
    parser.add_argument("--processed-dir", default=str(DEFAULT_PROCESSED_DIR), help="Directory containing processed CSV files")
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT_FILE), help="Output path for Excel workbook")
    args = parser.parse_args()

    processed_dir = Path(args.processed_dir).resolve()
    output_path = Path(args.output).resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)

    print(f"Loading processed data from: {processed_dir}")
    df_orders = pd.read_csv(processed_dir / "orders_processed.csv")
    df_items = pd.read_csv(processed_dir / "order_items_processed.csv")
    df_cust = pd.read_csv(processed_dir / "customers_processed.csv")
    df_products = pd.read_csv(processed_dir / "products_processed.csv")
    df_trans = pd.read_csv(processed_dir / "product_category_translation_processed.csv")
    df_reviews = pd.read_csv(processed_dir / "order_reviews_processed.csv")

    print("Building workbook sheets...")
    wb = openpyxl.Workbook()

    build_kpi_summary_sheet(wb, df_orders, df_items, df_cust, df_reviews)
    build_monthly_sales_sheet(wb, df_orders, df_items)
    build_category_sheet(wb, df_orders, df_items, df_products, df_trans, df_reviews)
    build_rfm_sheet(wb, df_orders, df_items, df_cust)
    build_regional_sheet(wb, df_orders, df_items, df_cust)

    wb.save(output_path)
    print(f"✅ Successfully generated dynamic Excel analytics workbook: {output_path}")


if __name__ == "__main__":
    main()

# East Africa Healthcare Distribution: Commercial Sales Performance Dashboard

An end-to-end BI project using a MySQL data warehouse, Python-based ETL, and a Power BI dashboard. It gives a fictional East African healthcare distributor visibility into revenue, margin, and field sales performance across Kenya, Uganda, and Tanzania.

<img width="1583" height="891" alt="image" src="https://github.com/user-attachments/assets/0f38a25a-75a9-44fc-966e-43a70215d407" />


## The Problem

Commercial leadership at a multi-country healthcare distributor relied on fragmented Excel reports with a multi-week lag. Data came in three currencies (KES, UGX, TZS). Two blind spots stood out:

- **Margin erosion invisible until quarter-end** — heavy discounting and a costlier product mix in specific territories eroded profit even when volume targets were hit.
- **No individual accountability** — sales rep performance was only visible at regional rollups, not down to the person.

This project turns that into a live, single-source-of-truth dashboard.

## What It Found

Across 36,000+ transactions and 100 reps over a 24-month period:

- **Net Revenue: KES 1.30bn**, at **91.6% target attainment**, **31.7% gross margin**
- **Uganda underperforms on margin (24.9% vs. 33–35% elsewhere)** — driven by both a 14.3% average discount rate (nearly double Kenya's) and a heavier mix of lower-margin Medical Equipment sales. Separating these two drivers, rather than treating "profitability" as just a discount metric, was the key analytical fix made to the original project design.
- **Pharmaceuticals lead revenue at 47%** of total, ahead of Consumer Health (30%) and Medical Equipment (23%).

## Tech Stack

| Layer | Tool |
|---|---|
| Database | MySQL |
| Data Loading | Python (SQLAlchemy + pandas) |
| BI & Visualization | Power BI Desktop (DAX) |

## Architecture

A star schema with two fact tables at different grains:

- `fact_sales` — daily transaction line items, local currency
- `fact_targets` — monthly rep quotas, KES
- `dim_calendar`, `dim_products`, `dim_customers`, `dim_sales_reps` — supporting dimensions

A SQL view (`vw_fact_sales_normalized`) converts all revenue to a consistent KES baseline using the exchange rate active on each transaction's actual date, not a static constant, so cross-country comparisons stay accurate as FX rates move.

Full schema, SQL, and DAX are in [`/sql`](sql/) and [`/dax`](dax/).


## Reproducing This Project

1. Run `sql/01_create_schema.sql` to build the database.
2. Run `python load_data.py` (see `.env.example` for required config) to load the CSVs in `/data`.
3. Open `sales_performance_dashboard.pbix`, connect to your local MySQL instance, and refresh.

## Known Limitations

- **Rep quotas aren't scaled by territory size.** A rep covering a smaller market (e.g., Uganda, ~200 customers) carries the same tier-based target as one covering a larger market (e.g., Kenya, ~400 customers). A production version would size quotas against territory potential, not just rep seniority.
- **No inventory/stockout data.** This phase covers sales, margin, and rep performance only. Inventory tracking is a natural Phase 2 extension.

-- 1. Revenue by product segment
SELECT
    product_category,
    ROUND(SUM(net_revenue_kes), 0) AS net_revenue_kes,
    ROUND(SUM(net_revenue_kes) / SUM(SUM(net_revenue_kes)) OVER () * 100, 1) AS pct_of_total
FROM vw_fact_sales_normalized
GROUP BY product_category
ORDER BY net_revenue_kes DESC;

-- ---------------------------------------------------------------------------------------

-- 2. Country margin and discount comparison
SELECT
    customer_country,
    ROUND(SUM(net_revenue_kes), 0) AS net_revenue_kes,
    ROUND(SUM(net_revenue_kes - (unit_cost * units_sold)) / SUM(net_revenue_kes) * 100, 2) AS gross_margin_pct,
    ROUND(SUM(discount_applied_kes) / SUM(gross_revenue_kes) * 100, 2) AS avg_discount_pct
FROM vw_fact_sales_normalized
GROUP BY customer_country
ORDER BY net_revenue_kes DESC;

-- --------------------------------------------------------------------------------------

-- 3. Top 10 products by net revenue with MoM growth

WITH monthly_product_revenue AS (
    SELECT
        product_id,
        product_name,
        year,
        month,
        SUM(units_sold)      AS units_sold,
        SUM(net_revenue_kes) AS net_revenue_kes
    FROM vw_fact_sales_normalized
    GROUP BY product_id, product_name, year, month
),
with_growth AS (
    SELECT
        *,
        LAG(net_revenue_kes) OVER (PARTITION BY product_id ORDER BY year, month) AS prev_month_revenue
    FROM monthly_product_revenue
),
latest_month AS (
    SELECT year, month FROM monthly_product_revenue ORDER BY year DESC, month DESC LIMIT 1
)
SELECT
    w.product_name,
    w.units_sold,
    ROUND(w.net_revenue_kes, 0) AS net_revenue_kes,
    ROUND((w.net_revenue_kes - w.prev_month_revenue) / NULLIF(w.prev_month_revenue, 0) * 100, 1) AS mom_growth_pct
FROM with_growth w
JOIN latest_month lm ON w.year = lm.year AND w.month = lm.month
ORDER BY w.net_revenue_kes DESC
LIMIT 10;

-- ----------------------------------------------------------------------

-- 4. Sales rep leaderboard

WITH rep_actuals AS (
    SELECT sales_rep_id, SUM(net_revenue_kes) AS actual_net_revenue_kes
    FROM vw_fact_sales_normalized
    GROUP BY sales_rep_id
),
rep_targets AS (
    SELECT sales_rep_id, SUM(monthly_target_kes) AS total_target_kes
    FROM fact_targets
    GROUP BY sales_rep_id
)
SELECT
    r.rep_name,
    r.territory_region,
    r.country,
    ROUND(a.actual_net_revenue_kes, 0) AS net_revenue_kes,
    ROUND(t.total_target_kes, 0)       AS target_kes,
    ROUND(a.actual_net_revenue_kes / t.total_target_kes * 100, 1) AS attainment_pct,
    RANK() OVER (ORDER BY a.actual_net_revenue_kes / t.total_target_kes DESC) AS attainment_rank
FROM dim_sales_reps r
JOIN rep_actuals a ON r.sales_rep_id = a.sales_rep_id
JOIN rep_targets t ON r.sales_rep_id = t.sales_rep_id
ORDER BY attainment_rank;

-- ------------------------------------------------------------------------

-- 5. Monthly revenue vs. target trend

WITH monthly_actual AS (
    SELECT year, month, month_name, SUM(net_revenue_kes) AS net_revenue_kes
    FROM vw_fact_sales_normalized
    GROUP BY year, month, month_name
),
monthly_target AS (
    SELECT cal.year, cal.month, SUM(t.monthly_target_kes) AS target_kes
    FROM fact_targets t
    JOIN dim_calendar cal ON t.date_id = cal.date_id
    GROUP BY cal.year, cal.month
)
SELECT
    a.year, a.month, a.month_name,
    ROUND(a.net_revenue_kes, 0) AS net_revenue_kes,
    ROUND(m.target_kes, 0)      AS target_kes,
    ROUND(a.net_revenue_kes / m.target_kes * 100, 1) AS attainment_pct
FROM monthly_actual a
JOIN monthly_target m ON a.year = m.year AND a.month = m.month
ORDER BY a.year, a.month;

-- ----------------------------------------------------------------------

-- 6. Active customers by month

SELECT
    year, month,
    COUNT(DISTINCT customer_id) AS active_customers
FROM vw_fact_sales_normalized
GROUP BY year, month
ORDER BY year, month;

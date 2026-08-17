CREATE OR REPLACE VIEW vw_fact_sales_normalized AS
SELECT
    s.invoice_line_id,
    s.date_id,
    cal.calendar_year,
    cal.calendar_month,
    cal.month_name,
    cal.calendar_quarter,
    c.customer_id,
    c.customer_name,
    c.customer_type,
    c.country AS customer_country,
    p.product_id,
    p.product_name,
    p.category AS product_category,
    p.sub_category AS product_sub_category,
    p.unit_cost,
    r.sales_rep_id,
    r.rep_name,
    r.territory_region,
    s.units_sold,
    s.gross_revenue_local,
    s.discount_applied_local,
    CASE
        WHEN c.country = 'Uganda' THEN s.gross_revenue_local / cal.ugx_to_kes_rate
        WHEN c.country = 'Tanzania' THEN s.gross_revenue_local / cal.tzs_to_kes_rate
        ELSE s.gross_revenue_local
    END AS gross_revenue_kes,
    CASE
        WHEN c.country = 'Uganda' THEN s.discount_applied_local / cal.ugx_to_kes_rate
        WHEN c.country = 'Tanzania' THEN s.discount_applied_local / cal.tzs_to_kes_rate
        ELSE s.discount_applied_local
    END AS discount_applied_kes,
    CASE
        WHEN c.country = 'Uganda' THEN (s.gross_revenue_local - s.discount_applied_local) / cal.ugx_to_kes_rate
        WHEN c.country = 'Tanzania' THEN (s.gross_revenue_local - s.discount_applied_local) / cal.tzs_to_kes_rate
        ELSE (s.gross_revenue_local - s.discount_applied_local)
    END AS net_revenue_kes
FROM fact_sales s
JOIN dim_customers  c  ON s.customer_id  = c.customer_id
JOIN dim_products   p  ON s.product_id   = p.product_id
JOIN dim_sales_reps r  ON s.sales_rep_id = r.sales_rep_id
JOIN dim_calendar   cal ON s.date_id = cal.date_id;
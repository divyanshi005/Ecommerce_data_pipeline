CREATE VIEW analytics.top_categories AS
SELECT
    COALESCE(product_category_name_english, 'unknown') AS category,
    COUNT(*) AS items_sold,
    ROUND(SUM(price)::numeric, 2) AS product_revenue
FROM analytics.fact_order_items i
LEFT JOIN analytics.dim_products p
    ON i.product_id = p.product_id
JOIN analytics.fact_orders o
    ON i.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY product_revenue DESC
LIMIT 10;

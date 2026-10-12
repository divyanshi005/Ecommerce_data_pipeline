
-- 1. Check for orphan records in fact tables
SELECT 'orders_missing_customers' AS check_name, COUNT(*) AS failures
FROM analytics.fact_orders f
LEFT JOIN analytics.dim_customers d
    ON f.customer_id = d.customer_id
WHERE d.customer_id IS NULL

UNION ALL

SELECT 'items_missing_products', COUNT(*)
FROM analytics.fact_order_items f
LEFT JOIN analytics.dim_products d
    ON f.product_id = d.product_id
WHERE d.product_id IS NULL

UNION ALL

SELECT 'items_missing_sellers', COUNT(*)
FROM analytics.fact_order_items f
LEFT JOIN analytics.dim_sellers d
    ON f.seller_id = d.seller_id
WHERE d.seller_id IS NULL;

-- 2. Revenue from order items (price only)
SELECT
    ROUND(SUM(price)::numeric, 2) AS product_revenue,
    ROUND(SUM(freight_value)::numeric, 2) AS freight_revenue,
    ROUND(SUM(item_total)::numeric, 2) AS total_item_value
FROM analytics.fact_order_items;

-- 3. Orders by status
SELECT
    order_status,
    COUNT(*) AS order_count
FROM analytics.fact_orders
GROUP BY order_status
ORDER BY order_count DESC;

-- 4. Monthly order volume
SELECT
    DATE_TRUNC('month', order_purchase_timestamp)::date AS order_month,
    COUNT(*) AS total_orders
FROM analytics.fact_orders
GROUP BY 1
ORDER BY 1;



-- A. Compare item value across order statuses
SELECT
    o.order_status,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(i.price)::numeric, 2) AS product_revenue,
    ROUND(SUM(i.freight_value)::numeric, 2) AS freight_value
FROM analytics.fact_orders o
JOIN analytics.fact_order_items i
    ON o.order_id = i.order_id
GROUP BY o.order_status
ORDER BY product_revenue DESC NULLS LAST;

-- B. Monthly order growth
WITH monthly_orders AS (
    SELECT
        DATE_TRUNC('month', order_purchase_timestamp)::date AS order_month,
        COUNT(*) AS total_orders
    FROM analytics.fact_orders
    GROUP BY 1
)
SELECT
    order_month,
    total_orders,
    LAG(total_orders) OVER (ORDER BY order_month) AS previous_month_orders,
    ROUND(
        100.0 * (total_orders - LAG(total_orders) OVER (ORDER BY order_month))
        / NULLIF(LAG(total_orders) OVER (ORDER BY order_month), 0),
        2
    ) AS month_over_month_growth_pct
FROM monthly_orders
ORDER BY order_month;

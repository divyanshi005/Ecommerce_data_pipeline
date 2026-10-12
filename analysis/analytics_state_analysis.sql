CREATE VIEW analytics.state_analysis AS
SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    ROUND(SUM(i.price)::numeric, 2) AS product_revenue
FROM analytics.fact_orders o
JOIN analytics.dim_customers c
    ON o.customer_id = c.customer_id
JOIN analytics.fact_order_items i
    ON o.order_id = i.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY product_revenue DESC;

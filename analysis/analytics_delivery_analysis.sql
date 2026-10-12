CREATE VIEW analytics.delivery_analysis AS
SELECT
    COUNT(*) AS delivered_orders,
    ROUND(
        AVG(EXTRACT(EPOCH FROM (
            order_delivered_customer_date - order_purchase_timestamp
        )) / 86400)::numeric, 2
    ) AS avg_delivery_days,
    ROUND(
        AVG(EXTRACT(EPOCH FROM (
            order_delivered_customer_date - order_estimated_delivery_date
        )) / 86400)::numeric, 2
    ) AS avg_days_vs_estimate,
    COUNT(*) FILTER (
        WHERE order_delivered_customer_date > order_estimated_delivery_date
    ) AS late_deliveries
FROM analytics.fact_orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;

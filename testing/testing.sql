
-- -- 1. Customer IDs
-- SELECT
--     COUNT(*) AS total_rows,
--     COUNT(customer_id) AS non_null_ids,
--     COUNT(DISTINCT customer_id) AS unique_ids
-- FROM staging.customers;

-- -- 2. Order IDs
-- SELECT
--     COUNT(*) AS total_rows,
--     COUNT(order_id) AS non_null_ids,
--     COUNT(DISTINCT order_id) AS unique_ids
-- FROM staging.orders;

-- -- 3. Order-item composite key
-- SELECT
--     COUNT(*) AS total_rows,
--     COUNT(*) FILTER (
--         WHERE order_id IS NULL OR order_item_id IS NULL
--     ) AS missing_key_rows,
--     COUNT(*) - COUNT(DISTINCT (order_id, order_item_id))
--         AS duplicate_key_rows
-- FROM staging.order_items;

-- -- 4. Orders referencing missing customers
-- SELECT COUNT(*) AS orphan_orders
-- FROM staging.orders o
-- LEFT JOIN staging.customers c
--     ON o.customer_id = c.customer_id
-- WHERE c.customer_id IS NULL;

-- -- 5. Order items referencing missing orders
-- SELECT COUNT(*) AS orphan_order_items
-- FROM staging.order_items oi
-- LEFT JOIN staging.orders o
--     ON oi.order_id = o.order_id
-- WHERE o.order_id IS NULL;

-- -- 6. Order items referencing missing products
-- SELECT COUNT(*) AS orphan_products
-- FROM staging.order_items oi
-- LEFT JOIN staging.products p
--     ON oi.product_id = p.product_id
-- WHERE p.product_id IS NULL;

-- -- 7. Order items referencing missing sellers
-- SELECT COUNT(*) AS orphan_sellers
-- FROM staging.order_items oi
-- LEFT JOIN staging.sellers s
--     ON oi.seller_id = s.seller_id
-- WHERE s.seller_id IS NULL;

-- SELECT
--     order_status,
--     COUNT(*) AS total_orders,
--     COUNT(*) FILTER (
--         WHERE order_approved_at IS NULL
--     ) AS missing_approval,
--     COUNT(*) FILTER (
--         WHERE order_delivered_carrier_date IS NULL
--     ) AS missing_carrier_date,
--     COUNT(*) FILTER (
--         WHERE order_delivered_customer_date IS NULL
--     ) AS missing_delivery_date
-- FROM staging.orders
-- GROUP BY order_status
-- ORDER BY total_orders DESC;
-- SELECT
--     COUNT(*) FILTER (
--         WHERE order_approved_at < order_purchase_timestamp
--     ) AS approval_before_purchase,

--     COUNT(*) FILTER (
--         WHERE order_delivered_carrier_date < order_purchase_timestamp
--     ) AS carrier_before_purchase,

--     COUNT(*) FILTER (
--         WHERE order_delivered_customer_date < order_delivered_carrier_date
--     ) AS delivery_before_carrier,

--     COUNT(*) FILTER (
--         WHERE order_delivered_customer_date < order_purchase_timestamp
--     ) AS delivery_before_purchase,

--     COUNT(*) FILTER (
--         WHERE order_estimated_delivery_date < order_purchase_timestamp
--     ) AS estimate_before_purchase
-- FROM staging.orders;
-- SELECT
--     COUNT(*) AS delivered_orders,
--     ROUND(
--         AVG(
--             EXTRACT(
--                 EPOCH FROM (
--                     order_delivered_customer_date
--                     - order_purchase_timestamp
--                 )
--             ) / 86400
--         )::numeric,
--         2
--     ) AS avg_delivery_days,
--     ROUND(
--         AVG(
--             EXTRACT(
--                 EPOCH FROM (
--                     order_estimated_delivery_date
--                     - order_delivered_customer_date
--                 )
--             ) / 86400
--         )::numeric,
--         2
--     ) AS avg_days_before_estimated_date
-- FROM staging.orders
-- WHERE order_status = 'delivered'
--   AND order_delivered_customer_date IS NOT NULL;


-- SELECT
--     order_id,
--     order_status,
--     order_purchase_timestamp,
--     order_approved_at,
--     order_delivered_carrier_date,
--     order_delivered_customer_date,
--     order_estimated_delivery_date,
--     CASE
--         WHEN order_delivered_carrier_date < order_purchase_timestamp
--             THEN 'Carrier before purchase'
--         WHEN order_delivered_customer_date < order_delivered_carrier_date
--             THEN 'Delivery before carrier'
--     END AS anomaly_type
-- FROM staging.orders
-- WHERE order_delivered_carrier_date < order_purchase_timestamp
--    OR order_delivered_customer_date < order_delivered_carrier_date
-- ORDER BY order_purchase_timestamp
-- LIMIT 50;


-- SELECT
--     COUNT(*) AS total_reviews,
--     COUNT(*) FILTER (
--         WHERE review_creation_date IS NULL
--            OR BTRIM(review_creation_date) = ''
--     ) AS missing_creation_dates,
--     COUNT(*) FILTER (
--         WHERE review_answer_timestamp IS NULL
--            OR BTRIM(review_answer_timestamp) = ''
--     ) AS missing_answer_timestamps
-- FROM staging.order_reviews;
-- SELECT
--     review_id,
--     review_score,
--     review_creation_date,
--     review_answer_timestamp
-- FROM staging.order_reviews
-- LIMIT 10;

-- SELECT
--     COUNT(*) AS total_rows,
--     COUNT(review_creation_date) AS valid_creation_dates,
--     COUNT(review_answer_timestamp) AS valid_answer_timestamps
-- FROM staging.order_reviews_typed;

-- SELECT column_name, data_type
-- FROM information_schema.columns
-- WHERE table_schema = 'staging'
--   AND table_name = 'order_reviews_typed'
-- ORDER BY ordinal_position;

-- SELECT COUNT(*) AS total_rows
-- FROM analytics.dim_customers;

-- SELECT
--     COUNT(*) AS total_rows,
--     COUNT(customer_id) AS non_null_customer_ids,
--     COUNT(DISTINCT customer_id) AS unique_customer_ids
-- FROM analytics.dim_customers;

-- SELECT *
-- FROM analytics.dim_customers
-- LIMIT 5;


-- SELECT 'dim_products' AS table_name, COUNT(*) AS total_rows
-- FROM analytics.dim_products
-- UNION ALL
-- SELECT 'dim_sellers', COUNT(*)
-- FROM analytics.dim_sellers;

-- SELECT
--     COUNT(*) AS total_products,
--     COUNT(DISTINCT product_id) AS unique_product_ids,
--     COUNT(product_category_name_english) AS translated_categories
-- FROM analytics.dim_products;

-- SELECT
--     COUNT(*) AS total_sellers,
--     COUNT(DISTINCT seller_id) AS unique_seller_ids
-- FROM analytics.dim_sellers;


-- SELECT 'fact_orders' AS table_name, COUNT(*) AS total_rows
-- FROM analytics.fact_orders
-- UNION ALL
-- SELECT 'fact_order_items', COUNT(*)
-- FROM analytics.fact_order_items
-- UNION ALL
-- SELECT 'fact_payments', COUNT(*)
-- FROM analytics.fact_payments;

-- -- Check the grain: one row per order
-- SELECT
--     COUNT(*) AS total_rows,
--     COUNT(DISTINCT order_id) AS unique_orders
-- FROM analytics.fact_orders;

-- -- Check the grain: one row per order item
-- SELECT
--     COUNT(*) AS total_rows,
--     COUNT(DISTINCT (order_id, order_item_id)) AS unique_order_items
-- FROM analytics.fact_order_items;

-- -- Payment totals and basic checks
-- SELECT
--     COUNT(*) AS payment_rows,
--     SUM(payment_value) AS total_payment_value,
--     MIN(payment_value) AS minimum_payment,
--     MAX(payment_value) AS maximum_payment
-- FROM analytics.fact_payments;



-- -- Compare orders by status before and after joining order items
-- SELECT
--     o.order_status,
--     COUNT(*) AS orders_in_fact_orders,
--     COUNT(i.order_id) AS matching_order_item_rows,
--     COUNT(DISTINCT i.order_id) AS orders_with_items
-- FROM analytics.fact_orders o
-- LEFT JOIN analytics.fact_order_items i
--     ON o.order_id = i.order_id
-- GROUP BY o.order_status
-- ORDER BY orders_in_fact_orders DESC;


SELECT
    o.order_status,
    COUNT(*) AS orders_without_items
FROM analytics.fact_orders o
LEFT JOIN analytics.fact_order_items i
    ON o.order_id = i.order_id
WHERE i.order_id IS NULL
GROUP BY o.order_status
ORDER BY orders_without_items DESC;

-- Confirm staging and analytics item counts
SELECT
    (SELECT COUNT(*) FROM staging.order_items) AS staging_item_rows,
    (SELECT COUNT(*) FROM analytics.fact_order_items) AS analytics_item_rows;

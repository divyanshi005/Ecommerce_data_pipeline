CREATE SCHEMA IF NOT EXISTS analytics;

-- 1. One row per order
CREATE TABLE analytics.fact_orders AS
SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM staging.orders;

-- 2. One row per item within an order
CREATE TABLE analytics.fact_order_items AS
SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value,
    price + freight_value AS item_total
FROM staging.order_items;

-- 3. One row per payment record
CREATE TABLE analytics.fact_payments AS
SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM staging.order_payments;

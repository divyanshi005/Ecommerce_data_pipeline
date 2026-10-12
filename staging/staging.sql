
CREATE TABLE staging.customers AS
SELECT
    NULLIF(TRIM(customer_id), '') AS customer_id,
    NULLIF(TRIM(customer_unique_id), '') AS customer_unique_id,
    customer_zip_code_prefix,
    NULLIF(TRIM(customer_city), '') AS customer_city,
    NULLIF(UPPER(TRIM(customer_state)), '') AS customer_state
FROM raw.customers;


CREATE TABLE staging.orders AS
SELECT
    NULLIF(TRIM(order_id), '') AS order_id,
    NULLIF(TRIM(customer_id), '') AS customer_id,
    NULLIF(LOWER(TRIM(order_status)), '') AS order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM raw.orders;


-- ============================================
-- Olist Data Engineering Project
-- Remaining staging tables
-- Database: olist_db
-- ============================================

-- 1. Order items
CREATE TABLE staging.order_items AS
SELECT
    TRIM(order_id) AS order_id,
    order_item_id,
    TRIM(product_id) AS product_id,
    TRIM(seller_id) AS seller_id,
    shipping_limit_date,
    price,
    freight_value
FROM raw.order_items;


-- 2. Order payments
CREATE TABLE staging.order_payments AS
SELECT
    TRIM(order_id) AS order_id,
    payment_sequential,
    LOWER(TRIM(payment_type)) AS payment_type,
    payment_installments,
    payment_value
FROM raw.order_payments;


-- 3. Order reviews
-- Preserve source timestamps as text for now.
-- We will validate and convert them in a later step.
CREATE TABLE staging.order_reviews AS
SELECT
    TRIM(review_id) AS review_id,
    TRIM(order_id) AS order_id,
    review_score,
    NULLIF(TRIM(review_comment_title), '') AS review_comment_title,
    NULLIF(TRIM(review_comment_message), '') AS review_comment_message,
    NULLIF(TRIM(review_creation_date), '') AS review_creation_date,
    NULLIF(TRIM(review_answer_timestamp), '') AS review_answer_timestamp
FROM raw.order_reviews;


-- 4. Products
CREATE TABLE staging.products AS
SELECT
    TRIM(product_id) AS product_id,
    NULLIF(TRIM(product_category_name), '') AS product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM raw.products;


-- 5. Sellers
CREATE TABLE staging.sellers AS
SELECT
    TRIM(seller_id) AS seller_id,
    seller_zip_code_prefix,
    NULLIF(TRIM(seller_city), '') AS seller_city,
    NULLIF(UPPER(TRIM(seller_state)), '') AS seller_state
FROM raw.sellers;


-- 6. Geolocation
-- Keep all source rows at this stage.
-- Deduplication will be investigated separately.
CREATE TABLE staging.geolocation AS
SELECT
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    NULLIF(TRIM(geolocation_city), '') AS geolocation_city,
    NULLIF(UPPER(TRIM(geolocation_state)), '') AS geolocation_state
FROM raw.geolocation;


-- 7. Product category translation
CREATE TABLE staging.product_category_translation AS
SELECT
    NULLIF(TRIM(product_category_name), '') AS product_category_name,
    NULLIF(TRIM(product_category_name_english), '') AS product_category_name_english
FROM raw.product_category_translation;

CREATE TABLE staging.order_reviews_typed AS
SELECT
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    NULLIF(TRIM(review_creation_date), '')::timestamp
        AS review_creation_date,
    NULLIF(TRIM(review_answer_timestamp), '')::timestamp
        AS review_answer_timestamp
FROM staging.order_reviews;

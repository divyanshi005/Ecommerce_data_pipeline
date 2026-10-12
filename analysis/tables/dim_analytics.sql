CREATE SCHEMA IF NOT EXISTS analytics;
CREATE TABLE analytics.dim_customers AS
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM staging.customers;


CREATE TABLE analytics.dim_products AS
SELECT
    p.product_id,
    p.product_category_name,
    t.product_category_name_english,
    p.product_name_lenght,
    p.product_description_lenght,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM staging.products p
LEFT JOIN staging.product_category_translation t
    ON p.product_category_name = t.product_category_name;

CREATE TABLE analytics.dim_sellers AS
SELECT
    seller_id,
    seller_city,
    seller_state,
    seller_zip_code_prefix
FROM staging.sellers;

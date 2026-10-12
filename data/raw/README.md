# Raw source data

Place the nine Olist CSV/Excel source files in this folder before profiling or ingestion. The files are intentionally excluded from Git because they are large source data, not application code.

Expected filenames:

- `olist_customers_dataset.xlsx`
- `olist_geolocation_dataset.xlsx`
- `olist_order_items_dataset.xlsx`
- `olist_order_payments_dataset.xlsx`
- `olist_order_reviews_dataset.csv`
- `olist_orders_dataset.xlsx`
- `olist_products_dataset.xlsx`
- `olist_product_category_name_translation.xlsx`
- `olist_sellers_dataset.xlsx`

Obtain the Olist Brazilian E-Commerce Public Dataset from its original Kaggle distribution and follow the dataset's terms. Keep these source files unchanged in this directory; derived data belongs in a separate layer.

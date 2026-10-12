
from pathlib import Path
import pandas as pd

# --------------------------------------------------
# 1. CONFIGURATION
# --------------------------------------------------

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data" / "raw"

FILES = {
    "customers": "olist_customers_dataset.xlsx",
    "geolocation": "olist_geolocation_dataset.xlsx",
    "order_items": "olist_order_items_dataset.xlsx",
    "payments": "olist_order_payments_dataset.xlsx",
    "reviews": "olist_order_reviews_dataset.csv",
    "orders": "olist_orders_dataset.xlsx",
    "products": "olist_products_dataset.xlsx",
    "sellers": "olist_sellers_dataset.xlsx",
    "category_translation": "olist_product_category_name_translation.xlsx",
}


# --------------------------------------------------
# 2. LOAD DATA
# --------------------------------------------------

def load_data():
    data = {}

    for table, filename in FILES.items():
        path = DATA_DIR / filename

        if not path.exists():
            print(f"WARNING: File not found: {path}")
            continue

        if path.suffix.lower() == ".csv":
            df = pd.read_csv(path)
        else:
            df = pd.read_excel(path)

        data[table] = df
        print(f"Loaded {table}: {df.shape[0]:,} rows, "
              f"{df.shape[1]} columns")

    return data


# --------------------------------------------------
# 3. BASIC DATA PROFILING
# --------------------------------------------------

def profile_tables(data):
    print("\n" + "=" * 65)
    print("BASIC TABLE PROFILING")
    print("=" * 65)

    for name, df in data.items():
        print(f"\n--- {name.upper()} ---")
        print(f"Rows: {len(df):,}")
        print(f"Columns: {len(df.columns)}")
        print(f"Fully duplicated rows: {df.duplicated().sum():,}")

        print("\nData types:")
        print(df.dtypes.to_string())

        null_counts = df.isna().sum()
        null_counts = null_counts[null_counts > 0]

        print("\nColumns with nulls:")
        if null_counts.empty:
            print("None")
        else:
            print(null_counts.to_string())

        print("\nUnique values in categorical columns:")
        for col in df.select_dtypes(
            include=["object", "category", "string"]
        ).columns:
            unique_count = df[col].nunique(dropna=True)

            if unique_count <= 20:
                print(f"{col}: {df[col].value_counts(dropna=False).to_dict()}")


# --------------------------------------------------
# 4. PRIMARY KEY CHECKS
# --------------------------------------------------

def check_primary_keys(data):
    print("\n" + "=" * 65)
    print("PRIMARY KEY CHECKS")
    print("=" * 65)

    candidate_keys = {
        "orders": ["order_id"],
        "customers": ["customer_id"],
        "products": ["product_id"],
        "sellers": ["seller_id"],
    }

    for table, columns in candidate_keys.items():
        if table not in data:
            continue

        df = data[table]

        if not all(col in df.columns for col in columns):
            print(f"{table}: required columns missing")
            continue

        key_data = df[columns]
        null_rows = key_data.isna().any(axis=1).sum()
        duplicate_rows = key_data.duplicated(keep=False).sum()

        print(f"\n{table}")
        print(f"Candidate key: {columns}")
        print(f"Rows with null key values: {null_rows:,}")
        print(f"Rows participating in duplicate keys: "
              f"{duplicate_rows:,}")
        print(f"Unique key combinations: "
              f"{len(key_data.drop_duplicates()):,}")

        if null_rows == 0 and duplicate_rows == 0:
            print("Result: Candidate key passes these checks.")
        else:
            print("Result: Investigate before defining a primary key.")


# --------------------------------------------------
# 5. COMPOSITE KEY CHECKS
# --------------------------------------------------

def check_composite_keys(data):
    print("\n" + "=" * 65)
    print("COMPOSITE KEY CHECKS")
    print("=" * 65)

    candidate_keys = {
        "order_items": ["order_id", "order_item_id"],
        "payments": ["order_id", "payment_sequential"],
    }

    for table, columns in candidate_keys.items():
        if table not in data:
            continue

        df = data[table]
        key_data = df[columns]

        print(f"\n{table}: {columns}")
        print("Null key rows:", key_data.isna().any(axis=1).sum())
        print(
            "Rows participating in duplicate composite keys:",
            key_data.duplicated(keep=False).sum()
        )


# --------------------------------------------------
# 6. REPEAT CUSTOMER ANALYSIS
# --------------------------------------------------

def analyze_customers(data):
    if "customers" not in data or "orders" not in data:
        return

    print("\n" + "=" * 65)
    print("CUSTOMER ANALYSIS")
    print("=" * 65)

    customers = data["customers"]
    orders = data["orders"]

    print("Unique customer_id values:",
          customers["customer_id"].nunique())
    print("Unique customer_unique_id values:",
          customers["customer_unique_id"].nunique())

    # Map each order to its customer identity.
    order_customers = orders.merge(
        customers[["customer_id", "customer_unique_id"]],
        on="customer_id",
        how="left",
        validate="many_to_one",
        indicator=True
    )

    unmatched = (order_customers["_merge"] != "both").sum()
    print(f"Orders without a matching customer: {unmatched:,}")

    # Count distinct orders per real-world customer identity.
    orders_per_customer = (
        order_customers.groupby("customer_unique_id")["order_id"]
        .nunique()
        .dropna()
    )

    repeat_customers = (orders_per_customer > 1).sum()
    total_customers_with_orders = len(orders_per_customer)

    print(f"Customer identities with orders: "
          f"{total_customers_with_orders:,}")
    print(f"Repeat customers: {repeat_customers:,}")

    if total_customers_with_orders:
        print(
            "Repeat customer percentage: "
            f"{repeat_customers / total_customers_with_orders * 100:.2f}%"
        )


# --------------------------------------------------
# 7. REFERENTIAL INTEGRITY CHECKS
# --------------------------------------------------

def check_foreign_key(
    child_df,
    child_column,
    parent_df,
    parent_column,
    relationship_name
):
    # Missing foreign keys are counted separately from orphan keys.
    missing = child_df[child_column].isna().sum()

    parent_keys = parent_df[parent_column].dropna().unique()

    orphan_mask = (
        child_df[child_column].notna()
        & ~child_df[child_column].isin(parent_keys)
    )

    print(f"\n{relationship_name}")
    print(f"Missing foreign key values: {missing:,}")
    print(f"Non-null values without a parent: "
          f"{orphan_mask.sum():,}")

    if orphan_mask.any():
        print("Sample unmatched values:")
        print(
            child_df.loc[orphan_mask, child_column]
            .drop_duplicates()
            .head(10)
            .to_list()
        )


def check_referential_integrity(data):
    print("\n" + "=" * 65)
    print("REFERENTIAL INTEGRITY")
    print("=" * 65)

    if not {"orders", "customers"}.issubset(data):
        print("Cannot check orders -> customers")
    else:
        check_foreign_key(
            data["orders"], "customer_id",
            data["customers"], "customer_id",
            "Orders -> Customers"
        )

    if not {"order_items", "products"}.issubset(data):
        print("Cannot check order_items -> products")
    else:
        check_foreign_key(
            data["order_items"], "product_id",
            data["products"], "product_id",
            "Order items -> Products"
        )

    if not {"order_items", "sellers"}.issubset(data):
        print("Cannot check order_items -> sellers")
    else:
        check_foreign_key(
            data["order_items"], "seller_id",
            data["sellers"], "seller_id",
            "Order items -> Sellers"
        )

    if not {"payments", "orders"}.issubset(data):
        print("Cannot check payments -> orders")
    else:
        check_foreign_key(
            data["payments"], "order_id",
            data["orders"], "order_id",
            "Payments -> Orders"
        )

    if not {"reviews", "orders"}.issubset(data):
        print("Cannot check reviews -> orders")
    else:
        check_foreign_key(
            data["reviews"], "order_id",
            data["orders"], "order_id",
            "Reviews -> Orders"
        )


# --------------------------------------------------
# 8. DELIVERY NULLS AND ORDER STATUS
# --------------------------------------------------

def analyze_delivery(data):
    if "orders" not in data:
        return

    print("\n" + "=" * 65)
    print("DELIVERY ANALYSIS")
    print("=" * 65)

    orders = data["orders"]

    date_columns = [
        "order_approved_at",
        "order_delivered_carrier_date",
        "order_delivered_customer_date",
    ]

    print("\nNull delivery-related timestamps by order status:")

    for col in date_columns:
        if col in orders.columns:
            print(f"\n{col}")
            print(
                orders.groupby("order_status", dropna=False)[col]
                .apply(lambda s: s.isna().sum())
                .to_string()
            )

    print("\nOrder counts by status:")
    print(orders["order_status"].value_counts(dropna=False).to_string())

    # Missing delivery dates may be expected for undelivered orders.
    if "order_delivered_customer_date" in orders.columns:
        missing_delivery = orders[
            orders["order_delivered_customer_date"].isna()
        ]

        print(
            "\nOrders missing customer delivery date: "
            f"{len(missing_delivery):,}"
        )
        print("Their statuses:")
        print(
            missing_delivery["order_status"]
            .value_counts(dropna=False)
            .to_string()
        )


# --------------------------------------------------
# 9. GEOLOCATION ANALYSIS
# --------------------------------------------------

def analyze_geolocation(data):
    if "geolocation" not in data:
        return

    print("\n" + "=" * 65)
    print("GEOLOCATION ANALYSIS")
    print("=" * 65)

    geo = data["geolocation"]
    zip_col = "geolocation_zip_code_prefix"

    print(f"Total rows: {len(geo):,}")
    print(f"Distinct ZIP prefixes: {geo[zip_col].nunique():,}")

    # Exact duplicate rows
    print(f"Exact duplicate rows: {geo.duplicated().sum():,}")

    # Rows sharing a ZIP prefix are not necessarily duplicates.
    print(
        "Rows beyond one row per ZIP prefix: "
        f"{len(geo) - geo[zip_col].nunique():,}"
    )

    # Count coordinate pairs per ZIP prefix.
    coords_per_zip = (
        geo.groupby(zip_col)[["geolocation_lat", "geolocation_lng"]]
        .apply(lambda g: g.drop_duplicates().shape[0])
    )

    print(
        "ZIP prefixes with multiple distinct coordinate pairs: "
        f"{(coords_per_zip > 1).sum():,}"
    )

    print("\nZIP prefixes with the most records:")
    print(
        geo[zip_col].value_counts().head(10).to_string()
    )


# --------------------------------------------------
# 10. RUN ALL CHECKS
# --------------------------------------------------

def main():
    data = load_data()

    if not data:
        print("No files loaded. Check DATA_DIR and filenames.")
        return

    profile_tables(data)
    check_primary_keys(data)
    check_composite_keys(data)
    analyze_customers(data)
    check_referential_integrity(data)
    analyze_delivery(data)
    analyze_geolocation(data)
    

if __name__ == "__main__":
    main()

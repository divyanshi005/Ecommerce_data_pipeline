"""Load the Olist source files into PostgreSQL's raw schema."""

import argparse
import os
from getpass import getpass
from pathlib import Path

import pandas as pd
from sqlalchemy import URL, create_engine, text


BASE_DIR = Path(__file__).resolve().parent
RAW_DIR = BASE_DIR / "data" / "raw"

# Source filename -> PostgreSQL table name
FILES = {
    "olist_customers_dataset.xlsx": "customers",
    "olist_geolocation_dataset.xlsx": "geolocation",
    "olist_order_items_dataset.xlsx": "order_items",
    "olist_order_payments_dataset.xlsx": "order_payments",
    "olist_order_reviews_dataset.csv": "order_reviews",
    "olist_orders_dataset.xlsx": "orders",
    "olist_products_dataset.xlsx": "products",
    "olist_sellers_dataset.xlsx": "sellers",
    "olist_product_category_name_translation.xlsx": "product_category_translation",
}


def read_source_file(path: Path) -> pd.DataFrame:
    """Read a supported CSV or Excel source file."""
    if path.suffix.lower() == ".csv":
        return pd.read_csv(path)
    if path.suffix.lower() in {".xlsx", ".xls"}:
        return pd.read_excel(path)
    raise ValueError(f"Unsupported file type: {path.suffix}")


def make_engine():
    """Build a connection from environment settings and prompt for its password."""
    password = os.getenv("OLIST_DB_PASSWORD") or getpass("PostgreSQL password: ")
    url = URL.create(
        drivername="postgresql+psycopg",
        username=os.getenv("OLIST_DB_USER", "postgres"),
        password=password,
        host=os.getenv("OLIST_DB_HOST", "localhost"),
        port=int(os.getenv("OLIST_DB_PORT", "5432")),
        database=os.getenv("OLIST_DB_NAME", "olist_db"),
    )
    return create_engine(url)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--replace",
        action="store_true",
        help="replace matching raw tables (destructive); default is to fail if a table exists",
    )
    args = parser.parse_args()

    missing_files = [name for name in FILES if not (RAW_DIR / name).is_file()]
    if missing_files:
        names = "\n  - ".join(missing_files)
        raise FileNotFoundError(f"Missing source files in {RAW_DIR}:\n  - {names}")

    engine = make_engine()
    try:
        with engine.begin() as conn:
            current_db = conn.execute(text("SELECT current_database()")).scalar_one()
            conn.execute(text("CREATE SCHEMA IF NOT EXISTS raw"))
        print(f"Connected to PostgreSQL database: {current_db}")

        if args.replace:
            print("Warning: --replace will drop and recreate each matching raw table.")

        for filename, table_name in FILES.items():
            path = RAW_DIR / filename
            print(f"\nReading {filename}...")
            frame = read_source_file(path)
            print(f"Read {len(frame):,} rows")
            frame.to_sql(
                name=table_name,
                con=engine,
                schema="raw",
                if_exists="replace" if args.replace else "fail",
                index=False,
                chunksize=1_000,
                method="multi",
            )
            print(f"Loaded raw.{table_name}: {len(frame):,} rows, {len(frame.columns)} columns")

        print("\n--- PostgreSQL row-count verification ---")
        with engine.connect() as conn:
            for table_name in FILES.values():
                count = conn.execute(
                    text(f'SELECT COUNT(*) FROM raw."{table_name}"')
                ).scalar_one()
                print(f"raw.{table_name}: {count:,} rows")
        print("\nRaw ingestion completed successfully.")
    finally:
        engine.dispose()


if __name__ == "__main__":
    main()

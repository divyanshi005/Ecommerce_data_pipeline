
# Olist E-commerce Data Engineering & Analytics

## Overview

An end-to-end SQL data engineering project using the Brazilian Olist e-commerce dataset. The project loads source data into PostgreSQL, builds cleaned staging tables, creates an analytics layer, validates data quality, and answers business questions using SQL.

## Architecture

**Excel source files → Raw tables → Staging tables → Analytics tables → Business insights**

- **Raw:** Source data loaded into PostgreSQL without modifying the original records.
- **Staging:** Cleaned text fields, normalized values, and converted review timestamps.
- **Analytics:** Dimension and fact tables designed for analytical queries.
- **Analysis:** SQL reports covering order trends, product categories, customer geography, and delivery performance.

## Data Model

### Dimension tables
- `analytics.dim_customers`
- `analytics.dim_products`
- `analytics.dim_sellers`

### Fact tables
- `analytics.fact_orders` — one row per order.
- `analytics.fact_order_items` — one row per item within an order.
- `analytics.fact_payments` — one row per payment record.

## Data Quality

Validation includes:
- Row-count reconciliation between raw, staging, and analytics tables.
- Primary-key uniqueness and non-null checks.
- Checks for orders without matching customers and items without matching products or sellers.
- Order timestamp anomaly checks.
- Investigation of orders without item records.

## Business Findings

- Delivered orders with recorded delivery timestamps: 96,470.
- Average purchase-to-delivery time: 12.56 days.
- Orders delivered after the estimated date: 7,826.
- Leading product category by delivered-order product revenue: health & beauty, at R$1.23 million.
- Leading customer state by delivered-order product revenue: São Paulo (SP), at R$5.07 million.
- November 2017 recorded 7,544 orders, up 62.90% from October 2017.

These figures describe the analyzed dataset and should not be interpreted as current market statistics.

## Technology Stack

- PostgreSQL
- SQL
- `psql`
- Excel source files
- Git and GitHub

## Running the Project

1. Install PostgreSQL and ensure `psql` is available.
2. Create the `olist_db` database.
3. Load the original dataset into the `raw` schema.
4. Run the SQL scripts in dependency order: staging tables, typed review timestamps, analytics dimensions, analytics fact tables, data quality checks, and business analysis scripts.
5. Compare the resulting row counts and validation outputs with the documented checks.

Update script filenames and loading instructions to match the final contents of your repository.

## Future Improvements

- Automate extraction and loading with Python.
- Add repeatable, idempotent transformations and database constraints.
- Orchestrate workflows with Apache Airflow.
- Add automated data quality tests.
- Build a dashboard for business stakeholders.
- Containerize the pipeline using Docker.



# Running the project

## Repository contents

```text
olist-project/
├── analysis/                 # Analytics table definitions and example queries
├── data/raw/                 # Local source files; excluded from Git
├── sql/                      # Database schema bootstrap
├── staging/                  # Raw-to-staging SQL
├── testing/                  # Data quality and reconciliation SQL
├── ingestion.py              # Load source files into PostgreSQL raw schema
├── initial_profiling.py      # Source-level profiling checks
├── requirements.txt
└── PROJECT_LOG.txt           # Development history and lessons
```

The Python virtual environment is local and should not be committed. Create it inside this directory by following the setup below.

## Prerequisites

- Python 3.11 or newer
- PostgreSQL 18 (or a compatible supported PostgreSQL release)
- The Olist source data files listed in [data/raw/README.md](data/raw/README.md)

## Setup

From this directory in PowerShell:

```powershell
py -3.11 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
```

Create a local database named `olist_db` using your PostgreSQL administrator tools, then bootstrap its schemas:

```powershell
psql -U postgres -d olist_db -f .\sql\00_create_schemas.sql
```

The loader reads connection settings from `OLIST_DB_HOST`, `OLIST_DB_PORT`, `OLIST_DB_NAME`, and `OLIST_DB_USER`. Defaults are `localhost`, `5432`, `olist_db`, and `postgres`. It prompts for the password. Alternatively, set `OLIST_DB_PASSWORD` in the current shell; never commit credentials.

## Run the project

Profile the source files (loads all files into pandas memory):

```powershell
python .\initial_profiling.py
```

Load the nine files into PostgreSQL:

```powershell
python .\ingestion.py
```

The default ingestion mode stops if a destination raw table already exists. To deliberately replace all matching raw tables and reload them, use:

```powershell
python .\ingestion.py --replace
```

`--replace` drops/recreates destination tables through pandas `to_sql`; use it only when that data can be overwritten. The loader reports row counts after insertion.

## SQL execution order

Connect to `olist_db` and run these scripts in order:

1. `sql/00_create_schemas.sql` (once; safe to rerun)
2. `staging/staging.sql` (after raw ingestion)
3. `analysis/tables/dim_analytics.sql`
4. `analysis/tables/fact_analytics.sql`
5. Queries in `analysis/` and checks in `testing/testing.sql`

The staging and analytics table scripts use `CREATE TABLE`, so they are intended for a fresh layer. If you rerun them after the tables exist, PostgreSQL will report that the relation already exists. Drop/rebuild those derived tables deliberately after reviewing their dependencies. `testing/testing.sql` contains exploratory queries; run each relevant statement after its referenced tables have been created.

## Current limitations

- The raw Excel files are not tracked; users must obtain them separately.
- The staging and analytics SQL scripts are currently hand-run and not fully idempotent.
- The profiler loads entire Excel files and can use substantial memory, especially for geolocation.
- Database ingestion has not been claimed as successful until the reported database row counts are observed.

# Import necessary libraries

import os
from pathlib import Path
from urllib.parse import quote_plus

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text


# 1. Load credentials from .env

load_dotenv()

DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = quote_plus(os.getenv("DB_PASSWORD"))  # escapes @, #, etc. so the URL parses correctly
DB_NAME = os.getenv("DB_NAME")
CSV_DIR = Path(os.getenv("CSV_DIR"))

CONN_STRING = f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
engine = create_engine(CONN_STRING)


# 2. Loading dims before facts

LOAD_ORDER = [
    ("dim_calendar.csv",    "dim_calendar"),
    ("dim_products.csv",    "dim_products"),
    ("dim_customers.csv",   "dim_customers"),
    ("dim_sales_reps.csv",  "dim_sales_reps"),
    ("fact_sales.csv",      "fact_sales"),
    ("fact_targets.csv",    "fact_targets"),
]

def load_csv_to_table(filename, table_name, conn):
    filepath = CSV_DIR / filename
    parse_dates = ["calendar_date"] if table_name == "dim_calendar" else None
    df = pd.read_csv(filepath, parse_dates=parse_dates)

    df.to_sql(
        name=table_name,
        con=conn,
        if_exists="append",
        index=False,
        method="multi",
        chunksize=1000,
    )
    return len(df)


# 3. Run the load, table by table

def main():
    print(f"Connecting to {DB_NAME} at {DB_HOST}:{DB_PORT} ...")

    with engine.begin() as conn:
        loaded_counts = {}
        for filename, table_name in LOAD_ORDER:
            print(f"Loading {filename} -> {table_name} ...")
            n_rows = load_csv_to_table(filename, table_name, conn)
            loaded_counts[table_name] = n_rows
            print(f"  {n_rows:,} rows inserted.")

    print("\nAll tables loaded successfully.\n")

    
    # 4. Validation to confirm DB row counts match source CSV row counts

    print("Validating row counts (CSV vs. DB) ...")
    with engine.connect() as conn:
        all_match = True
        for filename, table_name in LOAD_ORDER:
            db_count = conn.execute(text(f"SELECT COUNT(*) FROM {table_name}")).scalar()
            csv_count = loaded_counts[table_name]
            status = "OK" if db_count == csv_count else "MISMATCH"
            if status == "MISMATCH":
                all_match = False
            print(f"  {table_name:<18} CSV: {csv_count:>7,}  DB: {db_count:>7,}  [{status}]")

    if all_match:
        print("\nAll row counts match. Load verified.")
    else:
        print("\nRow count mismatch detected — review the log above.")

if __name__ == "__main__":
    main()
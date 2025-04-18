#!/usr/bin/env python3
"""
create_external_table.py

Creates an external Redshift Spectrum table for airplane crash data stored in S3 as Parquet.
Also drops the old table if it exists.

Required ENV variables:
- REDSHIFT_HOST
- REDSHIFT_PORT
- REDSHIFT_DB
- REDSHIFT_USER
- REDSHIFT_PASSWORD
- REDSHIFT_ROLE_ARN
- S3_BUCKET
"""

import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

# Redshift connection info
host = os.getenv("REDSHIFT_HOST")
port = int(os.getenv("REDSHIFT_PORT", 5439))
dbname = os.getenv("REDSHIFT_DB")
user = os.getenv("REDSHIFT_USER")
password = os.getenv("REDSHIFT_PASSWORD")

# External schema/table info
schema_name = "spectrum_schema"
table_name = "airplane_crashes_parquet"
external_db = "airplane_crashes"
iam_role_arn = os.getenv("REDSHIFT_ROLE_ARN")
bucket = os.getenv("S3_BUCKET")

# SQL statements
create_schema_sql = f"""
CREATE EXTERNAL SCHEMA IF NOT EXISTS {schema_name}
FROM data catalog
DATABASE '{external_db}'
IAM_ROLE '{iam_role_arn}';
"""

drop_table_sql = f"""
DROP TABLE IF EXISTS {schema_name}.{table_name};
"""

create_table_sql = f"""
CREATE EXTERNAL TABLE {schema_name}.{table_name} (
  crash_date        date,
  location          varchar,
  operator          varchar,
  type              varchar,
  aircraft_maker    varchar,
  aboard            int,
  fatalities        int,
  ground            int,
  survivors         int,
  is_fatal          boolean,
  crash_severity    varchar
)
PARTITIONED BY (
  year int
)
STORED AS PARQUET
LOCATION 's3://{bucket}/plane_crashes/processed_parquet/';
"""

def main():
    print("🚀 Connecting to Redshift...")
    conn = psycopg2.connect(
        dbname=dbname,
        user=user,
        password=password,
        host=host,
        port=port
    )
    conn.autocommit = True
    cur = conn.cursor()

    print("🧱 Creating external schema if not exists...")
    cur.execute(create_schema_sql)

    print("🧨 Dropping old table if exists...")
    cur.execute(drop_table_sql)

    print("✅ Creating new external table...")
    cur.execute(create_table_sql)

    cur.close()
    conn.close()
    print("🎯 Done! External table created successfully.")

if __name__ == "__main__":
    main()

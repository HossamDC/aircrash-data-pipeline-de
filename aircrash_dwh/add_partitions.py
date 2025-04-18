#!/usr/bin/env python3
"""
add_partitions.py

Reads partition folders (e.g., year=2021) from S3 and registers them in a Redshift Spectrum table.
Credentials and settings are pulled from environment variables for safety and reusability.

Required ENV variables:
- REDSHIFT_HOST
- REDSHIFT_PORT
- REDSHIFT_DB
- REDSHIFT_USER
- REDSHIFT_PASSWORD
- S3_BUCKET
"""

import boto3
import psycopg2
import os
import re
from dotenv import load_dotenv

load_dotenv()

# Load Redshift connection info from .env
host = os.getenv("REDSHIFT_HOST")
port = int(os.getenv("REDSHIFT_PORT", 5439))
dbname = os.getenv("REDSHIFT_DB")
user = os.getenv("REDSHIFT_USER")
password = os.getenv("REDSHIFT_PASSWORD")

# Spectrum table info
schema = "spectrum_schema"
table = "airplane_crashes_parquet"
bucket = os.getenv("S3_BUCKET")
prefix = "plane_crashes/processed_parquet/"

# Connect to Redshift
conn = psycopg2.connect(
    dbname=dbname, user=user, password=password, host=host, port=port
)
conn.autocommit = True
cur = conn.cursor()

# List S3 partition folders
s3 = boto3.client("s3")
result = s3.list_objects_v2(Bucket=bucket, Prefix=prefix, Delimiter='/')

# Extract and register year partitions
partitions = []
for obj in result.get('CommonPrefixes', []):
    key = obj['Prefix']
    match = re.search(r"year=(\d{4})", key)
    if match:
        year = match.group(1)
        s3_path = f"s3://{bucket}/{key}"
        print(f"🧩 Registering partition year={year} -> {s3_path}")
        sql = f"""
        ALTER TABLE {schema}.{table}
        ADD IF NOT EXISTS PARTITION (year = {year})
        LOCATION '{s3_path}';
        """
        try:
            cur.execute(sql)
        except Exception as e:
            print(f"❌ Error adding year={year}: {e}")

cur.close()
conn.close()
print("✅ Partition registration complete.")

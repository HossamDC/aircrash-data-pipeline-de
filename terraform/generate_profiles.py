#!/usr/bin/env python3
"""
generate_profiles.py

This script reads Terraform outputs (tf_outputs.json) and generates a dbt profiles.yml
for the `aircrash_dwh` project. It extracts Redshift connection details and writes
the profile to ~/.dbt/profiles.yml. Password is taken from the environment variable
`REDSHIFT_PASSWORD`, and Terraform outputs file path can be overridden via `TF_OUTPUTS_PATH`.
"""
import json
import os
import sys

# Path to Terraform outputs JSON file (default: tf_outputs.json in current directory)
TF_OUTPUTS_PATH = os.environ.get("TF_OUTPUTS_PATH", "tf_outputs.json")

# Load Terraform outputs
try:
    with open(TF_OUTPUTS_PATH) as f:
        tf_outputs = json.load(f)
except FileNotFoundError:
    sys.exit(f"Error: Terraform outputs file not found at {TF_OUTPUTS_PATH}")

# Extract values from Terraform outputs
host_with_port = tf_outputs.get("redshift_host", {}).get("value")
if not host_with_port:
    sys.exit("Error: 'redshift_host' not found in Terraform outputs")
host = host_with_port.split(":")[0]  # Remove port if present

dbname = tf_outputs.get("redshift_db", {}).get("value")
user = tf_outputs.get("redshift_user", {}).get("value")

# Read Redshift password from environment variable
password = os.environ.get("REDSHIFT_PASSWORD")
if not password:
    sys.exit("Error: Environment variable 'REDSHIFT_PASSWORD' is not set")

# Build the dbt profile content
profile_content = f"""
aircrash_dwh:
  target: dev
  outputs:
    dev:
      type: redshift
      host: {host}
      user: {user}
      password: {password}
      port: 5439
      dbname: {dbname}
      schema: public
      threads: 4
      keepalives_idle: 0
      connect_timeout: 10
      sslmode: require
"""

# Ensure the ~/.dbt directory exists
profiles_dir = os.path.expanduser("~/.dbt")
os.makedirs(profiles_dir, exist_ok=True)

# Write the profile to profiles.yml
profiles_path = os.path.join(profiles_dir, "profiles.yml")
with open(profiles_path, "w") as f:
    f.write(profile_content)

print(f"✅ dbt profiles.yml generated at {profiles_path}")

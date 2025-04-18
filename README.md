# ✈️ Aircrash Data Pipeline (Public - Zoomcamp Final Project)

This project is a fully automated **end-to-end Data Engineering pipeline** built as part of the [Data Engineering Zoomcamp](https://github.com/DataTalksClub/data-engineering-zoomcamp). It ingests, processes, models, and visualizes airplane crash data using modern cloud-native tools.

---

## 📊 Project Goal

The objective of this pipeline is to build a reliable and scalable data platform that answers key analytical questions related to global airplane crashes. It helps track crash frequency, operator involvement, survival rates, aircraft models, and trends over time.

---

## 📊 Data Source

- **Source**: Hugging Face dataset: [nateraw/airplane-crashes-and-fatalities](https://huggingface.co/datasets/nateraw/airplane-crashes-and-fatalities)
- **Original Source**: Likely web-scraped from [PlaneCrashInfo.com](http://www.planecrashinfo.com/)
- **Format**: CSV
- **Fields**:
  - `Date`, `Location`, `Operator`, `Type` (aircraft), `Aboard`, `Fatalities`, `Ground`, `Survivors`, `Summary`

> The raw file is available as:
`s3://my-spark-stage-23-3-1998-v1-01/plane_crashes/raw_hf_airplane_crashes.csv`

---

## ✅ What This Pipeline Solves

- Extracts raw CSV airplane crash data
- Transforms it with Spark (adds severity scoring, survival count, and normalizes formats)
- Stores it partitioned by year in **Parquet** format on **Amazon S3**
- Loads the processed data as an **external Redshift Spectrum table**
- Models it into fact/dimension structure via **dbt**
- Visualizes KPIs and trends in **Amazon QuickSight**
- Entire flow orchestrated using **Prefect**, from infrastructure provisioning to final model run

---

## 📊 Architecture Diagram

![image](https://github.com/user-attachments/assets/1bba02b7-1333-4713-a554-769805aa47c5)


---

## 🚀 Pipeline Flow (Automated A to Z)

### 🪄 Orchestration (Prefect)
- Runs the full pipeline using a single command (`pipeline.py`)
- Tasks include: Terraform apply, pulling data, Spark job on EMR, Redshift schema/table creation, dbt model runs, and test jobs

![image](https://github.com/user-attachments/assets/3c754791-6a4f-443e-9899-9c188d02f556)
![image](https://github.com/user-attachments/assets/f9f3643d-9d5b-4289-a576-f26da27465cf)

### 🚧 Infrastructure (Terraform)
- Creates S3 bucket, EMR cluster, Redshift cluster, IAM roles

### ✨ Data Processing (Spark on EMR)
- Cleans and transforms the raw dataset:
  - Standardizes date format to `crash_date`
  - Adds fields: `survivors`, `is_fatal`, `crash_severity`
  - Partitions data by `year`

### 📑 Data Warehouse (Redshift Spectrum)
- Table created over the Parquet files
- Partitions dynamically added based on folder paths

### 📊 Data Modeling (dbt)
- Models split into:
  - `fact_plane_crashes`
  - `dim_aircraft`, `dim_operator`, `dim_date`

### 🔍 BI Dashboard (QuickSight)
- Connects directly to Redshift
- Shows crash trends, survival rates, worst aircraft types, etc.

---

## 📊 Dashboard Example

![image](https://github.com/user-attachments/assets/1f71c80f-642e-4dbd-9ff9-2faea8658da8)


---

## 🤹 Tech Stack Summary

| Tool | Role |
|------|------|
| **Terraform** | Infra provisioning (S3, EMR, Redshift, IAM) |
| **Spark on EMR** | Batch processing and transformation |
| **AWS S3** | Raw and processed data lake storage |
| **Redshift Spectrum** | External table queries on S3 data |
| **dbt** | Data modeling into fact/dim tables |
| **Prefect** | Workflow orchestration and automation |
| **QuickSight** | Business intelligence and dashboards |

---

## 🔧 Setup Instructions

### 1. Clone the Repo
```bash
git clone https://github.com/YOUR_USERNAME/aircrash-data-pipeline.git
cd aircrash-data-pipeline
```

### 2. Configure AWS Credentials
```bash
aws configure
# Add your AWS Access Key, Secret, Region (e.g., us-west-2)
```

### 3. Create `.env` File
```bash
cp .env.example .env
# Edit it and fill in your Redshift password, bucket, etc.
```

### 4. Run the Pipeline (Fully Automated)
```bash
prefect deploy
prefect agent start &
python perfect/pipeline.py
```

---

## 📂 Repo Structure

```bash
.
├── terraform/              # Infra as code (S3, EMR, Redshift)
├── scripts/                # Python scripts (Spark, data ingestion)
├── aircrash_dwh/           # dbt project (models, seeds, macros)
├── perfect/                # Prefect orchestration pipeline
├── docs/images/            # Architecture + dashboard screenshots
├── .env.example            # Example env vars for local secrets
└── README.md
```

---

## ⚡ Notes

- `generate_profiles.py` auto-creates `~/.dbt/profiles.yml` using Terraform output
- `.env` keeps secrets secure
- Orchestration covers the entire flow — no manual steps

---

## 🚫 What Not to Commit

Be sure your `.gitignore` excludes:
```
.terraform/
*.tfstate
*.pem
.env
*.pyc
__pycache__/
tf_outputs.json
dbt_packages/
target/
```

---

## 🎓 Credit
Project built by Hossam as part of the [DataTalksClub Data Engineering Zoomcamp](https://github.com/DataTalksClub/data-engineering-zoomcamp).


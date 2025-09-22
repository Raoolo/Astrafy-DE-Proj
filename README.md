# Chicago Taxi Trips – Weather Impact Analysis

This project want to reproduce an **end-to-end pipeline** on GCP to answer the following question posed by the city of Chicago:

> **Do weather conditions affect taxi trip duration?**

👉 [View the Looker Studio Dashboard](https://lookerstudio.google.com/s/vFsFpj5EHWE)

## Mini Data Pipeline (Terraform + GCS + BigQuery + dbt)

All resources are created via **Terraform**, data transformations are done with **dbt**, and results are presented in a **Looker Studio dashboard**. Infrastructure is managed through **Terraform**, and CI/CD through **GitHub Actions**.
The repo includes infrastructure-as-code, transformations and CI/CD pipelines. The data is hosted on the public dataset of BigQuery.

---

## Repo layout

```pgsql
.
├─ terraform/ # Infrastructure (GCP resources via Terraform)
│ ├─ providers.tf
│ ├─ variables.tf
│ ├─ main.tf
│ └─ outputs.tf
├─ taxi_dbt/ # dbt project (models + transformations)
│ ├─ models/
│ │ ├─ sources.yml
│ │ ├─ stg_taxi_trips.sql
│ │ └─ mart_taxi_weather_daily.sql
│ └─ dbt_project.yml
└─ .github/workflows/ # CI/CD pipelines (GitHub Actions)
├─ terraform.yml
└─ dbt.yml
```
---

## Pipeline Overview

### 1. **Infrastructure (Terraform)**
- Creates a **BigQuery dataset** (`taxi_raw`).
- Creates a **partitioned BigQuery table** `weather_daily`.
- Configures a **BigQuery Scheduled Query** that:
  - Backfills all weather data since 2023-06-01.
  - Runs **daily** to ingest yesterday’s weather.
- Applies **column-level security** to the `payment_type` field with a Data Catalog policy tag (only my email has access).

### 2. **Data Transformation (dbt)**
- `stg_taxi_trips`: filters Chicago Taxi Trips public dataset to **01/06/2023 – 31/12/2023**.
- `mart_taxi_weather_daily`: joins trips with weather, computes daily averages, and rounds to 1 decimal place.

### 3. **CI/CD**
- **Terraform workflow**: validates and plans on PRs, applies when merged into `main`.  
- **dbt workflow**: runs `dbt build` on pushes to validate models against BigQuery.

### 4. **Dashboard (Looker Studio)**
- Connected directly to `mart_taxi_weather_daily`.
- Shows:
  - **Trend line**: trip duration vs temperature over time.
  - **Scatter plot**: temperature vs average trip minutes.
  - **Rainy vs dry comparison**: average duration by precipitation category.

---

## Key Insight

Trips last slightly longer on rainy days, and we can also see that trips duration seems to be higher on colder days and viceversa, decreasing durring summer. This suggests that weather indeed has a measurable effect on taxi's trip duration, with warmer days probably favoring other forms of transport such as walking or cycling.


---

## How to Reproduce

### Prerequisites
- GCP project + billing enabled.
- Terraform (`>=1.6`), `gcloud` CLI, `dbt-bigquery` installed.
- GitHub repo with Actions enabled.

1. Clone repo & authenticate
```powershell
gcloud auth application-default login
gcloud config set project astrafy-de-proj
```

2. Terraform for infrastructure
```powershell
cd terraform
terraform init
terraform apply -auto-approve
```

3. Run dbt locally
```powershell
cd taxi_dbt
dbt build
```

4. dbt for transformations
```powershell
cd taxi_dbt
dbt build
```

5. Open the Looker Studio Dashboard
[View the Looker Studio Dashboard](https://lookerstudio.google.com/s/vFsFpj5EHWE)

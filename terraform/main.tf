resource "google_project_service" "storage" {
  project = var.project_id
  service = "storage.googleapis.com"
}

resource "google_project_service" "bigquery_datatransfer" {
  project = var.project_id
  service = "bigquerydatatransfer.googleapis.com"
}

resource "google_service_account" "bq_transfer" {
  account_id   = "bq-transfer-sched"
  display_name = "BQ Scheduled Query SA"
}

# gives permissions to bq SA to run jobs
resource "google_project_iam_member" "bq_transfer_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.bq_transfer.email}"
}

resource "google_project_iam_member" "bq_transfer_user" {
  project = var.project_id
  role    = "roles/bigquery.user"
  member  = "serviceAccount:${google_service_account.bq_transfer.email}"
}

resource "google_bigquery_dataset_iam_member" "bq_transfer_dataset_owner" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.raw.dataset_id
  role       = "roles/bigquery.dataOwner"
  member     = "serviceAccount:${google_service_account.bq_transfer.email}"
}

resource "google_storage_bucket" "raw" {
  name                        = var.gcs_bucket_name
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true

  versioning {
    enabled = true
  }

  depends_on = [google_project_service.storage]
}

resource "google_bigquery_dataset" "raw" {
  dataset_id                 = var.bq_dataset_id
  location                   = var.bq_location
  delete_contents_on_destroy = true
}

resource "google_data_catalog_taxonomy" "security_taxonomy" {
  display_name = "Security"
  description  = "Policy tags for fine-grained access to columns"
  region       = "us"
}

resource "google_data_catalog_policy_tag" "pt_payment_type" {
  taxonomy     = google_data_catalog_taxonomy.security_taxonomy.name
  display_name = "SENSITIVE_PAYMENT"
  description  = "Payment method details"
}

resource "google_data_catalog_policy_tag_iam_binding" "pt_payment_type_reader" {
  policy_tag = google_data_catalog_policy_tag.pt_payment_type.name
  role       = "roles/datacatalog.categoryFineGrainedReader"
  members    = var.policytag_readers
}

# to delete
output "payment_type_policy_tag_name" {
  value = google_data_catalog_policy_tag.pt_payment_type.name
}

resource "google_bigquery_table" "weather_daily" {
  dataset_id = google_bigquery_dataset.raw.dataset_id
  table_id   = "weather_daily"

  deletion_protection = false

  time_partitioning {
    type  = "DAY"
    field = "weather_date"
  }

  schema = jsonencode([
    { name = "weather_date", type = "DATE", mode = "REQUIRED" },
    { name = "station_id", type = "STRING", mode = "REQUIRED" },
    { name = "temp_avg_c", type = "FLOAT", mode = "NULLABLE" },
    { name = "temp_min_c", type = "FLOAT", mode = "NULLABLE" },
    { name = "temp_max_c", type = "FLOAT", mode = "NULLABLE" },
    { name = "wind_max", type = "FLOAT", mode = "NULLABLE" },
    { name = "wind_avg", type = "FLOAT", mode = "NULLABLE" },
    { name = "prcp_mm", type = "FLOAT", mode = "NULLABLE" }
  ])
}


resource "google_bigquery_data_transfer_config" "weather_loader" {
  display_name           = "weather_daily_chicago"
  data_source_id         = "scheduled_query"
  location               = var.bq_location
  schedule               = var.weather_schedule
  destination_dataset_id = google_bigquery_dataset.raw.dataset_id
  service_account_name   = google_service_account.bq_transfer.email

  params = {
    query = <<-SQL
      -- Merge daily weather for Chicago O'Hare (USAF 725300, WBAN 94846)
      -- Source: bigquery-public-data.noaa_gsod.gsod2023 

      MERGE `${var.project_id}.${google_bigquery_dataset.raw.dataset_id}.weather_daily` T
      USING (
        WITH gsod AS (
          SELECT
            DATE(CONCAT(CAST(year AS STRING), '-', CAST(mo AS STRING), '-', CAST(da AS STRING))) AS weather_date,
            stn, wban,
            CAST(NULLIF(temp, 9999.9) AS FLOAT64) AS mean_f,
            CAST(NULLIF(max,  9999.9) AS FLOAT64) AS max_f,
            CAST(NULLIF(min,  9999.9) AS FLOAT64) AS min_f,
            CAST(NULLIF(CAST(mxpsd AS FLOAT64), 999.9) AS FLOAT64)  AS wind_max,
            CAST(NULLIF(CAST(wdsp  AS FLOAT64), 999.9)  AS FLOAT64) AS wind_avg,
            CAST(NULLIF(prcp, 99.99)  AS FLOAT64) AS prcp
          FROM `bigquery-public-data.noaa_gsod.gsod2023`
          WHERE stn = '725300' AND wban = '94846'  -- Chicago O'Hare
            -- AND _TABLE_SUFFIX BETWEEN '2023' AND FORMAT_DATE('%Y', CURRENT_DATE())
        )
        SELECT
          weather_date,
          CONCAT(stn, '-', wban) AS station_id,
          SAFE_DIVIDE((mean_f - 32) * 5, 9)  AS t_avg_c,
          SAFE_DIVIDE((min_f  - 32) * 5, 9)  AS t_min_c,
          SAFE_DIVIDE((max_f  - 32) * 5, 9)  AS t_max_c,
	  wind_max * 1.852 		     AS wind_max_kmh,
	  wind_avg * 1.852		     AS wind_avg_kmh,
          prcp * 25.4                        AS prcp_mm
        FROM gsod
        WHERE weather_date BETWEEN '2023-06-01' AND DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
      ) S
      ON T.weather_date = S.weather_date AND T.station_id = S.station_id
      WHEN MATCHED THEN
        UPDATE SET
          temp_avg_c = S.t_avg_c, temp_min_c = S.t_min_c, temp_max_c = S.t_max_c, wind_max = S.wind_max_kmh, wind_avg = S.wind_avg_kmh, prcp_mm = S.prcp_mm
      WHEN NOT MATCHED THEN
        INSERT (weather_date, station_id, temp_avg_c, temp_min_c, temp_max_c, wind_max, wind_avg, prcp_mm)
        VALUES (S.weather_date, S.station_id, S.t_avg_c, S.t_min_c, S.t_max_c, S.wind_max_kmh, S.wind_avg_kmh, S.prcp_mm);
    SQL
  }

  depends_on = [
    google_project_service.bigquery_datatransfer,
    google_bigquery_table.weather_daily,
    google_project_iam_member.bq_transfer_job_user,
    google_project_iam_member.bq_transfer_user,
    google_bigquery_dataset_iam_member.bq_transfer_dataset_owner
  ]
}

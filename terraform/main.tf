resource "google_bigquery_dataset" "raw" {
  dataset_id                 = var.bq_dataset_id
  location                   = "EU"
  delete_contents_on_destroy = true
}

resource "google_project_service" "storage" {
  project = var.project_id
  service = "storage.googleapis.com"
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

# test 2 ci/cd
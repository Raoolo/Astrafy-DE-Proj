variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Default region for resources"
  type        = string
  default     = "europe-west12"
}

variable "bq_dataset_id" {
  description = "Name of the BigQuery dataset to create"
  type        = string
  default     = "taxi_raw"
}

variable "gcs_bucket_name" {
  description = "Globally-unique bucket name"
  type        = string
}

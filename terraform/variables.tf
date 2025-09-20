variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Default region for resources"
  type        = string
  default     = "europe-west12"
}

variable "gcs_bucket_name" {
  description = "Globally-unique bucket name"
  type        = string
}

variable "bq_dataset_id" {
  description = "US dataset for public sources"
  type        = string
  default     = "taxi_raw"
}

variable "bq_location" {
  description = "Location for the US dataset"
  type        = string
  default     = "US"
}

variable "weather_schedule" {
  description = "When to run the weather merge job"
  type        = string
  default     = "every 24 hours"
}

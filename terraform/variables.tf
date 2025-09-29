variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Default region for resources"
  type        = string
  default     = "us-central1"
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

variable "policytag_readers" {
  description = "Principals allowed to read columns tagged as sensitive"
  type        = list(string)
  default     = []
}

variable "viewer_user_emails" {
  description = "Individual users who can view dataset & run jobs"
  type        = list(string)
  default     = [] # e.g. ["gatto.raulo@gmail.com"]
}

variable "viewer_groups" {
  description = "Google Groups who can view dataset & run jobs"
  type        = list(string)
  default     = [] # e.g. ["founders@astrafy.io"]
}

variable "dbt_tag_users" {
  description = "Principals allowed to attach policy tags (users and/or service accounts)"
  type        = list(string)
  default     = ["user:gatto.raul04@gmail.com", "serviceAccount:dbt-cicd@astrafy-de-proj.iam.gserviceaccount.com"]
}
terraform {
  required_version = ">= 1.6.0"
  backend "gcs" {
    bucket = "tfstate-chicago-taxi-bucket"
    prefix = "envs/default"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.40"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

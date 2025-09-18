terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  credentials = file("terraform-python.json")
  project = "gd-gcp-gridu-devops-t1-t2"
  region  = "us-central1"
}
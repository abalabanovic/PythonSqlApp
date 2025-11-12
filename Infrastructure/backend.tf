terraform {
  backend "gcs" {
    bucket = var.tf_backend_bucket
    prefix = "infra/state"
  }
}

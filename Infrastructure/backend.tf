terraform {
  backend "gcs" {
    bucket = "pythonsqlapp-tf-backend"
    prefix = "infra/state"
  }
}

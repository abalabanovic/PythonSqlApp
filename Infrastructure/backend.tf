terraform {
  backend "gcs" {
    bucket = "pythonsqlapp-tf-backend"
    prefix = "infra/state"
    credentials = file("service-account-key.json")
  }
}

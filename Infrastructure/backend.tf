terraform {
  backend "gcs" {
    bucket = "abalabanovic_pythonsql_state"
    prefix = "terraform/state"
    credentials = "terraform-python.json"
  }
}

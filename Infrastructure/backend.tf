terraform {
  backend "gcs" {
    bucket = "abalabanovic_pythonsql_state"
    prefix = "terraform/state"
    credentials = "abalabanovic-pythonsql.json"
  }
}
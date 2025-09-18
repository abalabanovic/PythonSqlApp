variable "region" {
    description = "Gcp region"
    type = string
    default = "us-central1"
}

variable "artifact_registry_name" {
    description = "Arfitact registry name for application"
    type = string
}

variable "project_id" {
  description = "GCP project id"
  type = string
}
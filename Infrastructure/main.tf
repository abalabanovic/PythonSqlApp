resource "google_artifact_registry_repository" "python-sql-application" {
 location = var.region
 repository_id = var.artifact_registry_name
 description = "Docker registry for python sql application"
 format = "DOCKER"
}


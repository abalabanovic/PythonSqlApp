output "artifact_registry_url" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_name}"
  description = "URL for pushing images to the Artifact Registry"
}
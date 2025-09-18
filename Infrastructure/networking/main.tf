resource "google_compute_network" "vpc" {
  name = var.vpc_name
  project = var.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gke_subnet" {
    name = var.gke_subnet
    project = var.project_id
    region = var.region
    ip_cidr_range = var.gke_subnet_cidr
    network = google_compute_network.vpc.id
    private_ip_google_access = true

}

resource "google_compute_subnetwork" "sql_subnet" {
 name = var.sql_subnet
 project = var.project_id
 region = var.region
 ip_cidr_range = var.sql_subnet_cidr
 network = google_compute_network.vpc.id
 private_ip_google_access = true
 
}
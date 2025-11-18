#Networking

resource "google_compute_network" "vpc" {
  name = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name = var.vpc_subnet_name
  region = var.region
  ip_cidr_range = var.private_cicd_range
  network = google_compute_network.vpc.id
}

resource "google_compute_global_address" "private_ip_range" {
  name          = "google-services-range" 
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16 
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "service_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}

resource "google_compute_address" "nat_ip" {
  name = "gke-nat-ip"
  region = var.region
}

resource "google_compute_router" "router" {
  name = "gke-nat-router"
  network = google_compute_network.vpc.id
  region = var.region
}

resource "google_compute_router_nat" "nat_config" {
  name = "gke-cloud-nat"
  router = google_compute_router.router.name
  region = google_compute_router.router.region

  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips = [google_compute_address.nat_ip.self_link]

  min_ports_per_vm = 64

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
  
}

# Artifact Registry

resource "google_artifact_registry_repository" "pythonsqlapp-registry" {
    location = var.region
    repository_id = var.application_gar_name
    format = var.gar_format
    description = "Container image repo for app"
}

# SQL Cloud Database

resource "google_sql_database_instance" "db_instance" {
    name = var.db_instance_name
    region = var.region
    database_version = var.database_version

    settings {
      tier = var.database_tier

      ip_configuration {
        ipv4_enabled = false
        private_network = google_compute_network.vpc.id
      }
    }
    depends_on = [
      google_service_networking_connection.service_vpc_connection
    ]

    deletion_protection = false
}

resource "google_sql_user" "db_admin" {
    name = var.admin_username
    instance = google_sql_database_instance.db_instance.name
    password = var.admin_password
}

resource "google_sql_user" "db_application_user" {
  name = var.application_user_name
  instance = google_sql_database_instance.db_instance.name
  password = var.application_user_password
}

resource "google_sql_database" "app_db" {
    name = var.db_name
    instance = google_sql_database_instance.db_instance.name
}

# GKE Cluster

resource "google_container_cluster" "gke_cluster" {
    name = var.gke_cluster_name
    location = var.zone

    networking_mode = "VPC_NATIVE"
    network = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id

    private_cluster_config {
      enable_private_nodes = true
      enable_private_endpoint = false
      master_ipv4_cidr_block = "172.16.0.0/28"
    }
    
    deletion_protection = false
    remove_default_node_pool = true
    initial_node_count = 1
  
}

resource "google_container_node_pool" "primary_nodes" {
    name = var.node_pool_name
    cluster = google_container_cluster.gke_cluster.name
    location = google_container_cluster.gke_cluster.location

    node_config {
      machine_type = var.node_machine_type
      disk_size_gb = var.disk_size_gb
      oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    }
    initial_node_count = var.initial_node_count
}
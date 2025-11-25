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
    host = "%"
    password = var.admin_password
    project = var.project_id
}

resource "google_sql_user" "db_application_user" {
    name = var.application_user_name
    instance = google_sql_database_instance.db_instance.name
    host = "%"
    password = var.application_user_password
    project = var.project_id
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

# Monitoring for application and Cloud SQL

resource "google_monitoring_notification_channel" "email_channel" {
  display_name = "Admin Email Alert Channel"
  type = "email"
  labels = {
    email_address = var.admin_email
  }
}

resource "google_monitoring_alert_policy" "cloudsql_disk_alert" {
  display_name = "Cloud SQL: Disk Utilization Near Full (>90%)"
  project = var.project_id

  combiner = "AND"
  conditions {
    display_name = "Disk utilization"
    condition_threshold {
      filter = "resource.type=\"cloudsql_database\" AND resource.label.database_id=\"${var.db_instance_name}\" AND metric.type=\"cloudsql.googleapis.com/database/disk/utilization\""
      duration = "300s"
      comparison = "COMPARISON_GT"
      threshold_value = 0.9
      
    }

  }
  notification_channels = [
    google_monitoring_notification_channel.email_channel.id
  ]
  
  documentation {
    mime_type = "text/markdown"
  }

}

resource "google_monitoring_dashboard" "cloudsql_dashboard" {
  project      = var.project_id

  dashboard_json = jsonencode({
    "displayName" : "Cloud SQL Health and Performance Dashboard",
    "gridLayout" : {
      "columns" : "2",
      "widgets" : [
        # Widget 1: CPU Utilization
        {
          "title" : "1. CPU Utilization (Percent)",
          "xyChart" : {
            "dataSets" : [{
              "timeSeriesQuery" : {
                "timeSeriesFilter" : {
                  "filter" : "metric.type=\"cloudsql.googleapis.com/database/cpu/utilization\" resource.type=\"cloudsql_database\"",
                  "aggregation" : { "alignmentPeriod" : "60s", "perSeriesAligner" : "ALIGN_MEAN" }
                },
                "unitOverride" : "percent"
              }
            }],
            "timeshiftDuration": "0s",
          }
        },
        # Widget 2: Disk Utilization
        {
          "title" : "2. Disk Utilization (Percent)",
          "xyChart" : {
            "dataSets" : [{
              "timeSeriesQuery" : {
                "timeSeriesFilter" : {
                  "filter" : "metric.type=\"cloudsql.googleapis.com/database/disk/utilization\" resource.type=\"cloudsql_database\"",
                  "aggregation" : { "alignmentPeriod" : "60s", "perSeriesAligner" : "ALIGN_MEAN" }
                },
                "unitOverride" : "percent"
              }
            }],
            "timeshiftDuration": "0s",
          }
        },
      ]
    }
  })
}

resource "google_monitoring_alert_policy" "gke_high_cpu_alert" {
  display_name = "GKE App: High Container CPU Usage (>80%)"
  project = var.project_id

  combiner = "AND"
  conditions {
    display_name = "Container CPU Utilization"
    condition_threshold {
      filter = "resource.type=\"k8s_container\" AND metric.type=\"kubernetes.io/container/cpu/core_usage_time\" AND metadata.user_labels.app=\"weather-app\""
      comparison = "COMPARISON_GT"
      duration = "120s"
      threshold_value = 0.8
      aggregations {
        per_series_aligner = "ALIGN_RATE"
        alignment_period = "60s"
        group_by_fields = ["resource.label.container_name", "resource.label.pod_name"]
      }

      
    }
  }
  notification_channels = [
    google_monitoring_notification_channel.email_channel.id
  ]
}

resource "google_monitoring_dashboard" "gke_app_dashboard" {
  project      = var.project_id

  dashboard_json = jsonencode({
    "displayName" : "GKE App & Pod Performance (Filtered by Label)",
    "gridLayout" : {
      "columns" : "2",
      "widgets" : [
        {
          "title" : "1. CPU Utilization (Container: weather-app)",
          "xyChart" : {
            "dataSets" : [{
              "timeSeriesQuery" : {
                "timeSeriesFilter" : {
                  "filter": "metric.type=\"kubernetes.io/container/cpu/core_usage_time\" AND resource.type=\"k8s_container\" AND resource.labels.namespace_name=\"weather-app\"",
                  "aggregation" : { "alignmentPeriod" : "60s", "perSeriesAligner" : "ALIGN_RATE" }
                },
                "unitOverride" : "1"
              }
            }]
          }
        },
        {
          "title" : "2. Memory Used (Container: weather-app)",
          "xyChart" : {
            "dataSets" : [{
              "timeSeriesQuery" : {
                "timeSeriesFilter" : {
                  "filter": "metric.type=\"kubernetes.io/container/memory/used_bytes\" AND resource.type=\"k8s_container\" AND metadata.user_labels.app=\"weather-app\"",
                  "aggregation" : { "alignmentPeriod" : "60s", "perSeriesAligner" : "ALIGN_MEAN" }
                },
                "unitOverride" : "bytes"
              }
            }]
          }
        },
        {
          "title" : "3. Storage usage (weather-app)",
          "xyChart" : {
            "dataSets" : [{
              "timeSeriesQuery" : {
                "timeSeriesFilter" : {
                  "filter": "metric.type=\"kubernetes.io/container/ephemeral_storage/used_bytes\" AND resource.type=\"k8s_container\" AND metadata.user_labels.app=\"weather-app\"",
                  "aggregation" : { "alignmentPeriod" : "60s", "crossSeriesReducer" : "REDUCE_SUM", "perSeriesAligner" : "ALIGN_MEAN", "groupByFields": ["resource.labels.pod_name"] }
                }
              }
            }]
          }
        },
            {
        "title": "4. Weather API Request Rate (per city)",
        "xyChart": {
          "dataSets": [{
            "timeSeriesQuery": {
              "prometheusQuery": "rate(weather_requests_total[1m]) * 60",
              "unitOverride": "1/min"
            }
          }],
          "timeshiftDuration": "0s"
        }
      }
    ]
  }
})
}
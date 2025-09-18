resource "google_sql_database_instance" "mysql-instance" {
 name = var.sql_instance_name
 database_version = var.database_version
 region = var.region
 project = var.project_id  

settings {
  tier = "db-f1-micro"

  ip_configuration {
    
    ipv4_enabled = false
    private_network = data.google_compute_network.vpc_main.self_link

    }
}
    deletion_protection = false
}

resource "google_sql_database" "app_db" {
    name = var.db_name
    instance = google_sql_database_instance.mysql-instance.name
    project = var.project_id
}

resource "google_sql_user" "db_user" {
    name = var.db_user
    instance = google_sql_database_instance.mysql-instance.name
    password = var.db_password
    project = var.project_id
}

output "cloud_sql_private_ip" {
    value = google_sql_database_instance.db_instance.private_ip_address
    description = "Private IP cloud sql instance"  
}
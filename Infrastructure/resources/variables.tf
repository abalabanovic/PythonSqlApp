variable "sql_instance_name" {
 description = "Cloud SQL instance name" 
 type = string
}

variable "database_version" {
  description = "SQL database version"
  type = string
  default = "MYSQL_8_0"
}

variable "region" {
 description = "Region"
 type = string
 default = "us-central1"
}

variable "project_id" {
  description = "Project id"
  type = string
}

variable "sql_instance_tier" {
  description = "Tier for SQL instance"
  type = string
  default = "db-f1-micro"
}

variable "db_name" {
    description = "Database name"
    type = string
}

variable "db_user" {
  description = "Database user"
  type = string
}

variable "db_password" {
  description = "Database password"
  type = string
}

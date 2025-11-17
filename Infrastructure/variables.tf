variable "project_id" {
    type = string
    description = "GCP project ID"
}

variable "region" {
    type = string
    description = "GCP zone"
    default = "us-central1"
}

variable "vpc_name" {
    type = string
    description = "Private VPC name"
}

variable "vpc_subnet_name" {
  type = string
  description = "Subnet for private VPC name"
}

variable "private_cicd_range" {
  type = string
  default = "10.0.0.0/24"
}

variable "application_gar_name" {
  type = string
  description = "name of GAR for application "
}

variable "gar_format" {
  type = string
  default = "DOCKER"
}

variable "db_instance_name" {
    type = string
    description = "Name for Cloud SQL"
}

variable "database_version" {
  type = string
  default = "MYSQL_8_0"
}

variable "database_tier" {
  type = string
  default = "db-f1-micro"
}

variable "db_name" {
    type = string
    description = "Database name"
}

variable "admin_username" {
  type = string
  description = "Admin username"
}

variable "admin_password" {
  type = string
  description = "Admin user password"
}

variable "application_user_name" {
  type = string
  description = "Application username"
}

variable "application_user_password" {
    type =  string
    description = "Application user password"
  
}

variable "gke_cluster_name" {
  type = string
  description = "GKE cluster name"
}

variable "node_machine_type" {
  type = string
  description = "Node machine type"
}

variable "node_pool_name" {
  type = string
}

variable "initial_node_count" {
  type = number
}
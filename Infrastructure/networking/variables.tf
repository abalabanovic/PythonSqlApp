variable "vpc_name" {
  type = string
  description = "VPC for sql and gke"
}

variable "gke_subnet_cidr" {
  type = string
  default = "10.10.0.0/24"
}

variable "sql_subnet_cidr" {
  type = string
  default = "10.20.0.0/24"
}

variable "region" {
    type = string
    default = "us-central1"
}

variable "gke_subnet" {
  type = string
}

variable "sql_subnet" {
  type = string
}

variable "project_id" {
  type = string
}
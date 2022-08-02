variable "vpc_id" {
  type = string
  
}
variable "redshift_cluster_name" {
  type = string
}

variable "private_subnets_db" {
  type    = set(string)
  default = []
}

variable "redshift_env" {
  type = string
}

variable "redshift_db_name" {
  type = string
}

variable "redshift_username" {
  type = string
}

variable "redshift_password" {
  type = string
}

variable "redshift_node_type" {
  type = string
}

variable "redshift_cluster_type" {
  type = string
  
}
variable "number_of_nodes" {
  type = number
}
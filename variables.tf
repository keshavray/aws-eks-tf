
# Variables for VPC
variable "name" {
  type = string

}
variable "environment" {
  type = string

}
variable "cidr" {
  description = "The CIDR block for the VPC."
  type        = string
}
variable "public_subnets" {

  description = "A map of availability zones to public cidrs"
  type        = map(string)

}
variable "private_subnets_app" {
  description = "A map of availability zones to private cidrs"
  type        = map(string)

}
variable "private_subnets_db" {
  description = "A map of availability zones to private cidrs"
  type        = map(string)

}
variable "enable_dns_hostnames" {
  default = true
}
variable "enable_dns_support" {
  default = true
}
variable "peering-name" {
  type = string
}

#varibles for EKS

variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type    = number
  default = "1.20"
}

variable "cluster_service_ipv4_cidr" {
  type    = string
  default = "172.20.0.0/16"
}

variable "cluster_endpoint_private_access_cidrs" {
  type    = list(any)
  default = ["0.0.0.0/0"]
}

variable "eks_node_group_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "cluster_endpoint_private_access" {
  type    = bool
  default = true
}

variable "cluster_endpoint_public_access" {
  type    = bool
  default = false
}

variable "private_subnet_ids" {
  type    = set(string)
  default = []
}

variable "tags" {
  type = map(string)
}
variable "vpc_id" {
  type    = string
  default = ""
}
variable "node_group_desired" {

  type    = number
  default = 1
}
variable "node_group_max_size" {
  type    = number
  default = 2
}
variable "node_group_min_size" {
  type    = number
  default = 1
}
variable "namespaces" {
  type = set(string)
}


# variable for RDS

variable "rds_name" {
  type = string
}

variable "engine" {
  type    = string
  default = "postgress"
}

variable "engine_version" {
  type    = string
  default = "13.1"
}

variable "username" {
  type    = string
  default = "ovradmin"
}

variable "rds_password" {
  type = string
}

variable "allocated_storage" {
  type    = number
  default = 5
}

variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "publicly_accessible" {
  type    = bool
  default = true
}

variable "skip_final_snapshot" {
  type    = bool
  default = false
}

# Variables for Redshift 

variable "redshift_cluster_name" {
  type = string
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

# varaible for discovery-site
variable discovery_domain_name {
    type = string
}
variable certificate_arn {
    type = string
}
variable discovery_alias {
    type = string
}

# varaible for patient-web-site
variable patient_web_domain_name {
    type = string
}
variable patient_web_alias {
    type = string
}
# variables for discovery-site otc

variable discovery_otc_domain_name {
    type = string
}
variable discovery_otc_alias {
    type = string
}

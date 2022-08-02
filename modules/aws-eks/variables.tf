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
  default = ["t3.micro"]
}

variable "cluster_endpoint_private_access" {
  type    = bool
  default = true
}

variable "cluster_endpoint_public_access" {
  type    = bool
  default = true
}

variable "environment" {
  type    = string
}

variable "namespaces" {
  type = set(string)
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
variable "log_retention" {

type = number
default = 30 

}

variable "name" {

  type    = string
  default = "ovr-dev"
}

variable "environment" {}

variable "cidr" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "public_subnets" {
  description = "A map of availability zones to public cidrs"
  type        = map(string)
  default = {

    us-east-2a = "",
    us-east-2b = "",
    us-east-2c = ""

  }
}

variable "private_subnets_app" {
  description = "A map of availability zones to private cidrs"
  type        = map(string)
  default = {

    us-east-2a = "",
    us-east-2b = "",
    us-east-2c = ""

  }
}
variable "private_subnets_db" {
  description = "A map of availability zones to private cidrs"
  type        = map(string)
  default = {

    us-east-2a = "",
    us-east-2b = "",
    us-east-2c = ""

  }
}
variable "enable_dns_hostnames" {
  default     = true
}
variable "enable_dns_support" {
  default     = true
}
variable "cluster_name" {
  type    = string
  default = ""
}

variable "peering-name" {
  type   = string
}  

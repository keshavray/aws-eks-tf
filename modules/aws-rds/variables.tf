variable "rds_name" {
  type = string
  default = "ovr-dev"
}

variable "vpc_id" {
  type = string
  
}

variable "engine" {
  type = string
  default = "postgres"
}

variable "engine_version" {
  type = string
  default = "13.3"
}

variable "username" {
  type = string
  default = "ovradmin"
}

variable "rds_password" {
  type = string
}

variable "allocated_storage" {
  type = number
  default = 5
}

variable "instance_class" {
  type = string
  default = "db.t3.micro"
}

variable "publicly_accessible" {
  type = bool
  default = false
}

variable "skip_final_snapshot" {
  type = bool
  default = false
}


variable "private_subnets_db" {
  type    = set(string)
  default = []
}

variable "monitoring_role" {
  type    = string
  default = "arn:aws:iam::182560659941:role/rds-monitoring-role"
}









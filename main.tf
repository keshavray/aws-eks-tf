
module "ovr-vpc" {


  source               = "./modules/aws-vpc"
  cidr                 = var.cidr
  name                 = var.name
  environment          = var.environment
  public_subnets       = var.public_subnets
  private_subnets_db   = var.private_subnets_db
  private_subnets_app  = var.private_subnets_app
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  cluster_name         = var.cluster_name
  peering-name         = var.peering-name
}

module "ovr-eks" {

  source                                = "./modules/aws-eks"
  cluster_name                          = var.cluster_name
  cluster_version                       = var.cluster_version
  tags                                  = var.tags
  environment                           = var.environment
  cluster_service_ipv4_cidr             = var.cluster_service_ipv4_cidr
  cluster_endpoint_private_access_cidrs = var.cluster_endpoint_private_access_cidrs
  vpc_id                                = module.ovr-vpc.vpc_id
  private_subnet_ids                    = module.ovr-vpc.private_subnets_app_id
  eks_node_group_instance_types         = var.eks_node_group_instance_types
  cluster_endpoint_private_access       = var.cluster_endpoint_private_access
  cluster_endpoint_public_access        = var.cluster_endpoint_public_access
  node_group_desired                    = var.node_group_desired
  node_group_max_size                   = var.node_group_max_size
  node_group_min_size                   = var.node_group_min_size
  namespaces                            = var.namespaces
}

module "ovr-rds" {

  source             = "./modules/aws-rds"
  rds_name           = var.rds_name
  rds_password       = var.rds_password
  private_subnets_db = module.ovr-vpc.private_db_subnet_ids
  vpc_id             = module.ovr-vpc.vpc_id
}

module "ovr-redshift" {

  source                = "./modules/aws-redshift"
  redshift_cluster_name = var.redshift_cluster_name
  redshift_env          = var.redshift_env
  vpc_id                = module.ovr-vpc.vpc_id
  private_subnets_db    = module.ovr-vpc.public_subnet_ids
  redshift_db_name      = var.redshift_db_name
  redshift_username     = var.redshift_username
  redshift_password     = var.redshift_password
  redshift_node_type    = var.redshift_node_type
  redshift_cluster_type = var.redshift_cluster_type
  number_of_nodes       = var.number_of_nodes
}


module "discovery-site" {

  source                = "./modules/discovery-site" 
  discovery_domain_name = var.discovery_domain_name
  environment           = var.environment
  discovery_alias       = var.discovery_alias
  certificate_arn       = var.certificate_arn
}


module "patient-website" {

  source                  = "./modules/patient-website" 
  patient_web_domain_name = var.patient_web_domain_name
  environment             = var.environment
  patient_web_alias       = var.patient_web_alias
  certificate_arn         = var.certificate_arn
}

module "discovery-site-otc" {

  source                    = "./modules/discovery-site-otc"
  discovery_otc_domain_name = var.discovery_otc_domain_name
  environment               = var.environment
  discovery_otc_alias       = var.discovery_otc_alias
  certificate_arn           = var.certificate_arn
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source      = "./modules/vpc"
  name_prefix = var.name_prefix
  vpc_cidr    = var.vpc_cidr
  az_a        = var.az_a
  az_b        = var.az_b
}

module "security" {
  source      = "./modules/security"
  name_prefix = var.name_prefix
  vpc_id      = module.vpc.vpc_id
}

module "database" {
  source            = "./modules/database"
  name_prefix       = var.name_prefix
  db_subnet_ids     = module.vpc.private_db_subnet_ids
  rds_sg_id         = module.security.rds_sg_id
  db_username       = var.db_username
  db_password       = var.db_password
  db_instance_class = var.db_instance_class
  db_engine_version = var.db_engine_version
  db_multi_az       = var.db_multi_az
}

module "compute" {
  source                 = "./modules/compute"
  name_prefix            = var.name_prefix
  vpc_id                 = module.vpc.vpc_id
  public_subnet_ids      = module.vpc.public_subnet_ids
  private_app_subnet_ids = module.vpc.private_app_subnet_ids
  alb_sg_id              = module.security.alb_sg_id
  ec2_sg_id              = module.security.ec2_sg_id
  rds_endpoint           = module.database.rds_endpoint
  instance_type          = var.instance_type
  min_size               = var.min_size
  max_size               = var.max_size
  desired_capacity       = var.desired_capacity
  db_user                = var.db_username
  db_password            = var.db_password
  db_name                = "mysql"
  app_repo_url           = var.app_repo_url
}

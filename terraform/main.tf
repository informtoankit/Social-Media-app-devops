module "vpc" {
  source = "./modules/vpc"

  project_name        = var.project_name
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  enable_flow_logs    = var.enable_flow_logs
}

module "networking" {
  source = "./modules/networking"

  project_name         = var.project_name
  vpc_id               = module.vpc.vpc_id
  public_subnet_ids    = module.vpc.public_subnet_ids
  private_subnet_ids   = module.vpc.private_subnet_ids
  internet_gateway_id  = module.vpc.internet_gateway_id
  availability_zones   = var.availability_zones
  nat_gateway_count    = var.nat_gateway_count
}

module "security" {
  source = "./modules/security"

  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
}

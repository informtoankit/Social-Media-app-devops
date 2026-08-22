output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "alb_security_group_id" {
  value = module.security.alb_security_group_id
}

output "eks_security_group_id" {
  value = module.security.eks_security_group_id
}

output "rds_security_group_id" {
  value = module.security.rds_security_group_id
}

output "nat_gateway_ips" {
  value = module.networking.nat_gateway_ips
}

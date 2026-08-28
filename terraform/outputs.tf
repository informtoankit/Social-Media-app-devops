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
output "s3_bucket_name" {
  value = module.s3.bucket_name
}

output "s3_bucket_arn" {
  value = module.s3.bucket_arn
}


output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}
output "alb_controller_role_arn" {
  value = module.alb_controller.iam_role_arn
}
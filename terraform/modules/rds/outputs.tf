output "db_endpoint" {
  value       = aws_db_instance.main.endpoint
  description = "RDS connection endpoint"
}

output "db_instance_id" {
  value = aws_db_instance.main.id
}

output "secrets_manager_arn" {
  value       = aws_secretsmanager_secret.db_credentials.arn
  description = "ARN of the Secrets Manager secret containing DB credentials"
}
output "db_endpoint" {
  value = module.rds.db_endpoint
}

output "secrets_manager_arn" {
  value = module.rds.secrets_manager_arn
}